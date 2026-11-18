package com.khmerbank.common.web;

import jakarta.servlet.http.HttpServletRequest;

/** Caller metadata for audit logs. Behind a proxy, configure server.forward-headers-strategy. */
public record ClientInfo(String ip, String userAgent) {

    public static ClientInfo from(HttpServletRequest request) {
        String ua = request.getHeader("User-Agent");
        if (ua != null && ua.length() > 255) {
            ua = ua.substring(0, 255);
        }
        return new ClientInfo(request.getRemoteAddr(), ua);
    }
}
