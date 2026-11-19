package com.khmerbank.auth.application;

import com.khmerbank.account.application.AccountService;
import com.khmerbank.account.domain.AccountType;
import com.khmerbank.auth.domain.User;
import com.khmerbank.auth.domain.UserDevice;
import com.khmerbank.auth.domain.UserProfile;
import com.khmerbank.auth.domain.UserStatus;
import com.khmerbank.auth.infrastructure.UserDeviceRepository;
import com.khmerbank.auth.infrastructure.UserProfileRepository;
import com.khmerbank.auth.infrastructure.UserRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.common.web.ClientInfo;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Maps a verified Firebase ID token to the local customer record.
 *
 * <ul>
 *   <li>First request of a Firebase user: the {@code users} row is created (or an existing row
 *       with the same email / phone is linked), and a default USD current account is opened.</li>
 *   <li>Every request: phone / email from the token are kept in sync, and the calling device
 *       (headers {@code X-Device-Id}, {@code X-Device-Name}, {@code X-Device-Platform}) is
 *       recorded so it shows up in the device list and can be revoked.</li>
 * </ul>
 */
@Service
public class FirebaseUserService {

    public static final String HEADER_DEVICE_ID = "X-Device-Id";
    public static final String HEADER_DEVICE_NAME = "X-Device-Name";
    public static final String HEADER_DEVICE_PLATFORM = "X-Device-Platform";

    private static final Set<String> PLATFORMS = Set.of("ANDROID", "IOS", "WEB");
    private static final Duration LAST_SEEN_RESOLUTION = Duration.ofMinutes(1);

    /** Device identification sent by the app; {@code null} when absent or malformed. */
    public record DeviceHeaders(String deviceId, String deviceName, String platform) {

        public static DeviceHeaders from(HttpServletRequest request) {
            String id = request.getHeader(HEADER_DEVICE_ID);
            String platform = request.getHeader(HEADER_DEVICE_PLATFORM);
            if (id == null || id.isBlank() || id.length() > 128 || platform == null
                    || !PLATFORMS.contains(platform.toUpperCase())) {
                return null;
            }
            String name = request.getHeader(HEADER_DEVICE_NAME);
            if (name != null && name.length() > 100) {
                name = name.substring(0, 100);
            }
            return new DeviceHeaders(id.trim(), name, platform.toUpperCase());
        }
    }

    private final UserRepository users;
    private final UserProfileRepository profiles;
    private final UserDeviceRepository devices;
    private final AccountService accountService;
    private final AuditService audit;
    private final Clock clock;

    public FirebaseUserService(UserRepository users, UserProfileRepository profiles, UserDeviceRepository devices,
                               AccountService accountService, AuditService audit, Clock clock) {
        this.users = users;
        this.profiles = profiles;
        this.devices = devices;
        this.accountService = accountService;
        this.audit = audit;
        this.clock = clock;
    }

    @Transactional
    public AuthenticatedUser authenticate(Jwt jwt, DeviceHeaders device, ClientInfo client) {
        Instant now = Instant.now(clock);
        User user = users.findByFirebaseUid(jwt.getSubject())
                .orElseGet(() -> provision(jwt, now, client));
        syncIdentity(user, jwt, now);
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ApiException(ErrorCode.USER_NOT_ACTIVE);
        }
        UUID deviceRowId = device == null ? null : touchDevice(user.getId(), device, authTime(jwt), now, client);
        return new AuthenticatedUser(user.getId(), deviceRowId);
    }

    private User provision(Jwt jwt, Instant now, ClientInfo client) {
        String email = email(jwt);
        String phone = jwt.getClaimAsString("phone_number");

        // Link a customer that existed before the move to Firebase (same email or phone).
        User user = (email == null ? null : users.findByEmailIgnoreCase(email).orElse(null));
        if (user == null && phone != null) {
            user = users.findByPhone(phone).orElse(null);
        }
        if (user != null && user.getFirebaseUid() == null) {
            user.setFirebaseUid(jwt.getSubject());
            user.setStatus(UserStatus.ACTIVE);
            user.setUpdatedAt(now);
            audit.success(user.getId(), "USER_LINKED_FIREBASE", "user", user.getId(), client, Map.of());
            return users.saveAndFlush(user);
        }

        user = new User();
        user.setFirebaseUid(jwt.getSubject());
        user.setStatus(UserStatus.ACTIVE);
        user.setCreatedAt(now);
        user.setUpdatedAt(now);
        users.saveAndFlush(user);
        users.assignRole(user.getId(), "CUSTOMER");

        UserProfile profile = new UserProfile();
        profile.setUserId(user.getId());
        profile.setFullNameEn(displayName(jwt, email));
        profile.setUpdatedAt(now);
        profiles.save(profile);

        accountService.open(user.getId(), AccountType.CURRENT, CurrencyCode.USD, "Main USD", client);
        audit.success(user.getId(), "USER_PROVISIONED", "user", user.getId(), client, Map.of());
        return user;
    }

    /** Firebase is the source of truth for the verified phone number and email. */
    private void syncIdentity(User user, Jwt jwt, Instant now) {
        boolean changed = false;
        String phone = jwt.getClaimAsString("phone_number");
        if (phone != null && !phone.equals(user.getPhone())) {
            user.setPhone(phone);
            user.setPhoneVerified(true); // Firebase only sets phone_number after SMS verification.
            changed = true;
        }
        String email = email(jwt);
        if (email != null && !email.equalsIgnoreCase(user.getEmail())) {
            user.setEmail(email);
            changed = true;
        }
        boolean emailVerified = Boolean.TRUE.equals(jwt.getClaimAsBoolean("email_verified"));
        if (email != null && emailVerified != user.isEmailVerified()) {
            user.setEmailVerified(emailVerified);
            changed = true;
        }
        if (changed) {
            user.setUpdatedAt(now);
        }
    }

    private UUID touchDevice(UUID userId, DeviceHeaders headers, Instant authTime, Instant now, ClientInfo client) {
        UserDevice device = devices.findByUserIdAndDeviceId(userId, headers.deviceId()).orElseGet(() -> {
            UserDevice d = new UserDevice();
            d.setUserId(userId);
            d.setDeviceId(headers.deviceId());
            d.setTrusted(true); // Sign-in (password / SMS) was verified by Firebase.
            d.setCreatedAt(now);
            return d;
        });
        if (device.getRevokedAt() != null) {
            // A revoked device stays blocked until the user signs in on it again.
            if (authTime == null || !authTime.isAfter(device.getRevokedAt())) {
                throw new ApiException(ErrorCode.DEVICE_REVOKED);
            }
            device.setRevokedAt(null);
            device.setTrusted(true);
            audit.success(userId, "DEVICE_REAUTHENTICATED", "user_device", device.getId(), client, Map.of());
        }
        boolean stale = device.getLastSeenAt() == null
                || device.getLastSeenAt().isBefore(now.minus(LAST_SEEN_RESOLUTION));
        if (device.getId() == null || stale || !Objects.equals(device.getDeviceName(), headers.deviceName())
                || !Objects.equals(device.getPlatform(), headers.platform())) {
            device.setDeviceName(headers.deviceName());
            device.setPlatform(headers.platform());
            device.setLastSeenAt(now);
            device = devices.save(device);
        }
        return device.getId();
    }

    private static Instant authTime(Jwt jwt) {
        Object value = jwt.getClaims().get("auth_time");
        if (value instanceof Number n) {
            return Instant.ofEpochSecond(n.longValue());
        }
        if (value instanceof Instant i) {
            return i;
        }
        return null;
    }

    private static String email(Jwt jwt) {
        String email = jwt.getClaimAsString("email");
        return email == null || email.isBlank() ? null : email.trim().toLowerCase();
    }

    private static String displayName(Jwt jwt, String email) {
        String name = jwt.getClaimAsString("name");
        if (name != null && !name.isBlank()) {
            return name.length() > 150 ? name.substring(0, 150) : name.trim();
        }
        if (email != null) {
            return email.substring(0, email.indexOf('@'));
        }
        return "Customer";
    }
}
