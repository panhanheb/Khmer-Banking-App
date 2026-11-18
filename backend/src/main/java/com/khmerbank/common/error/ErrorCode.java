package com.khmerbank.common.error;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    VALIDATION_ERROR(HttpStatus.BAD_REQUEST, "Validation failed"),
    WEAK_PASSWORD(HttpStatus.BAD_REQUEST, "Password does not meet the policy"),
    IDEMPOTENCY_KEY_REQUIRED(HttpStatus.BAD_REQUEST, "Idempotency-Key header is required"),
    INVALID_OTP(HttpStatus.BAD_REQUEST, "Invalid verification code"),
    OTP_EXPIRED(HttpStatus.BAD_REQUEST, "Verification code expired"),
    INVALID_PIN(HttpStatus.BAD_REQUEST, "Invalid transaction PIN"),
    PIN_NOT_SET(HttpStatus.BAD_REQUEST, "Transaction PIN has not been set"),

    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "Invalid phone number or password"),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "Authentication required"),
    TOKEN_EXPIRED(HttpStatus.UNAUTHORIZED, "Token expired"),
    TOKEN_INVALID(HttpStatus.UNAUTHORIZED, "Token invalid"),

    FORBIDDEN(HttpStatus.FORBIDDEN, "Access denied"),
    PHONE_NOT_VERIFIED(HttpStatus.FORBIDDEN, "Phone number not verified"),
    USER_NOT_ACTIVE(HttpStatus.FORBIDDEN, "User is not active"),

    NOT_FOUND(HttpStatus.NOT_FOUND, "Resource not found"),
    RECIPIENT_NOT_FOUND(HttpStatus.NOT_FOUND, "Recipient not found"),

    DUPLICATE(HttpStatus.CONFLICT, "Duplicate request"),
    IDEMPOTENCY_CONFLICT(HttpStatus.CONFLICT, "Idempotency-Key was already used with a different request"),
    PHONE_ALREADY_REGISTERED(HttpStatus.CONFLICT, "Phone number already registered"),
    EMAIL_ALREADY_REGISTERED(HttpStatus.CONFLICT, "Email already registered"),
    CONCURRENT_MODIFICATION(HttpStatus.CONFLICT, "Concurrent modification, please retry"),

    ACCOUNT_LOCKED(HttpStatus.LOCKED, "Account temporarily locked"),
    PIN_LOCKED(HttpStatus.LOCKED, "Transaction PIN temporarily locked"),

    INSUFFICIENT_BALANCE(HttpStatus.UNPROCESSABLE_ENTITY, "Insufficient balance"),
    LIMIT_EXCEEDED(HttpStatus.UNPROCESSABLE_ENTITY, "Transaction limit exceeded"),
    ACCOUNT_NOT_ACTIVE(HttpStatus.UNPROCESSABLE_ENTITY, "Account is not active"),
    SAME_ACCOUNT(HttpStatus.UNPROCESSABLE_ENTITY, "Source and destination accounts are the same"),
    CURRENCY_MISMATCH(HttpStatus.UNPROCESSABLE_ENTITY, "Currency not supported for this operation"),
    ACCOUNT_LIMIT_REACHED(HttpStatus.UNPROCESSABLE_ENTITY, "Maximum number of accounts reached"),

    RATE_LIMITED(HttpStatus.TOO_MANY_REQUESTS, "Too many requests"),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected error");

    private final HttpStatus status;
    private final String title;

    ErrorCode(HttpStatus status, String title) {
        this.status = status;
        this.title = title;
    }

    public HttpStatus status() {
        return status;
    }

    public String title() {
        return title;
    }
}
