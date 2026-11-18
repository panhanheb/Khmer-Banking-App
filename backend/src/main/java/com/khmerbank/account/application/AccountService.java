package com.khmerbank.account.application;

import com.khmerbank.account.api.AccountDtos.AccountResponse;
import com.khmerbank.account.domain.AccountBalance;
import com.khmerbank.account.domain.AccountStatus;
import com.khmerbank.account.domain.AccountType;
import com.khmerbank.account.domain.BankAccount;
import com.khmerbank.account.infrastructure.AccountBalanceRepository;
import com.khmerbank.account.infrastructure.BankAccountRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.config.AppProperties;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.web.ClientInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class AccountService {

    private final BankAccountRepository accounts;
    private final AccountBalanceRepository balances;
    private final AuditService audit;
    private final AppProperties props;
    private final Clock clock;

    public AccountService(BankAccountRepository accounts, AccountBalanceRepository balances, AuditService audit,
                          AppProperties props, Clock clock) {
        this.accounts = accounts;
        this.balances = balances;
        this.audit = audit;
        this.props = props;
        this.clock = clock;
    }

    @Transactional
    public AccountResponse open(UUID userId, AccountType type, CurrencyCode currency, String nickname, ClientInfo client) {
        if (type == AccountType.SYSTEM) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Account type not allowed");
        }
        if (accounts.countByPrimaryHolderIdAndStatusNot(userId, AccountStatus.CLOSED) >= props.accounts().maxPerUser()) {
            throw new ApiException(ErrorCode.ACCOUNT_LIMIT_REACHED);
        }
        Instant now = Instant.now(clock);

        BankAccount account = new BankAccount();
        account.setAccountNumber(nextAccountNumber());
        account.setOwnerType(BankAccount.OwnerType.CUSTOMER);
        account.setAccountType(type);
        account.setCurrency(currency);
        account.setStatus(AccountStatus.ACTIVE);
        account.setNickname(nickname == null || nickname.isBlank() ? defaultNickname(type, currency) : nickname.trim());
        account.setPrimaryHolderId(userId);
        account.setOpenedAt(now);
        accounts.saveAndFlush(account);
        accounts.addPrimaryHolder(account.getId(), userId);

        AccountBalance balance = new AccountBalance();
        balance.setAccountId(account.getId());
        balance.setCurrency(currency);
        balance.setLedgerBalance(BigDecimal.ZERO);
        balance.setAvailableBalance(BigDecimal.ZERO);
        balance.setHoldAmount(BigDecimal.ZERO);
        balance.setAllowNegative(false);
        balance.setUpdatedAt(now);
        balances.save(balance);

        audit.success(userId, "ACCOUNT_OPENED", "bank_account", account.getId(), client,
                Map.of("currency", currency.name(), "type", type.name()));
        return AccountResponse.of(account, balance);
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> list(UUID userId) {
        List<BankAccount> list = accounts.findOpenByHolder(userId);
        Map<UUID, AccountBalance> byId = balances.findByAccountIdIn(list.stream().map(BankAccount::getId).toList())
                .stream().collect(Collectors.toMap(AccountBalance::getAccountId, Function.identity()));
        return list.stream().map(a -> AccountResponse.of(a, byId.get(a.getId()))).toList();
    }

    @Transactional(readOnly = true)
    public AccountResponse get(UUID userId, UUID accountId) {
        BankAccount account = requireOwned(userId, accountId);
        AccountBalance balance = balances.findById(accountId).orElseThrow();
        return AccountResponse.of(account, balance);
    }

    /** Ownership check: unknown and foreign accounts both yield 404 so ids cannot be probed. */
    @Transactional(readOnly = true)
    public BankAccount requireOwned(UUID userId, UUID accountId) {
        return accounts.findByIdAndHolder(accountId, userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "Account not found"));
    }

    /** Branch code (3) + sequence (8) + Luhn check digit (1) = 12 digits. */
    String nextAccountNumber() {
        String body = props.accounts().branchCode() + String.format("%08d", accounts.nextAccountSequence());
        return body + luhnCheckDigit(body);
    }

    static int luhnCheckDigit(String digits) {
        int sum = 0;
        boolean dbl = true;
        for (int i = digits.length() - 1; i >= 0; i--) {
            int d = digits.charAt(i) - '0';
            if (dbl) {
                d *= 2;
                if (d > 9) {
                    d -= 9;
                }
            }
            sum += d;
            dbl = !dbl;
        }
        return (10 - (sum % 10)) % 10;
    }

    private static String defaultNickname(AccountType type, CurrencyCode currency) {
        return (type == AccountType.SAVINGS ? "Savings " : "Current ") + currency.name();
    }
}
