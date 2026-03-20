package com.org.chat_app.controller;

import com.org.chat_app.dto.AuthResponse;
import com.org.chat_app.dto.LoginRequest;
import com.org.chat_app.dto.SignupRequest;
import com.org.chat_app.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/signup")
    public AuthResponse signup(@RequestBody SignupRequest request) {
        return authService.signup(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @GetMapping("/me")
    public String me(@AuthenticationPrincipal String username) {
        return "Hello " + username;
    }
}