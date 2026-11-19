package com.khmerbank.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.error.GlobalExceptionHandler;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

import java.io.IOException;

/** Writes RFC 7807 bodies from servlet filters (outside the MVC exception handler). */
@Component
public class ProblemWriter {

    private final ObjectMapper objectMapper;

    public ProblemWriter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public void write(HttpServletResponse response, ErrorCode code, String detail) throws IOException {
        response.setStatus(code.status().value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), GlobalExceptionHandler.problem(code, detail));
    }
}
