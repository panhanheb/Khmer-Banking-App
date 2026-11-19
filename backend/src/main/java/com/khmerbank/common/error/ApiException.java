package com.khmerbank.common.error;

/** Business error that maps to an RFC 7807 response with a stable {@link ErrorCode}. */
public class ApiException extends RuntimeException {

    private final ErrorCode code;

    public ApiException(ErrorCode code) {
        this(code, code.title());
    }

    public ApiException(ErrorCode code, String detail) {
        super(detail);
        this.code = code;
    }

    public ErrorCode code() {
        return code;
    }
}
