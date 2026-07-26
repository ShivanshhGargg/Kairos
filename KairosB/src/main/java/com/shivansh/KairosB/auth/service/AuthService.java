package com.shivansh.KairosB.auth.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.shivansh.KairosB.auth.dto.request.LoginRequest;
import com.shivansh.KairosB.auth.dto.request.RegisterRequest;
import com.shivansh.KairosB.auth.dto.response.AuthResponse;
import com.shivansh.KairosB.auth.model.AuthProvider;
import com.shivansh.KairosB.auth.model.User;
import com.shivansh.KairosB.auth.repository.UserRepository;
import com.shivansh.KairosB.common.config.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final JwtService jwtService;
    private final EmailService emailService;
    private final GoogleTokenValidator googleTokenValidator;

    @Value("${app.verification-token-expiration-hours}")
    private long tokenExpirationHours;

    public AuthService(UserRepository userRepository,
                       JwtService jwtService,
                       EmailService emailService,
                       GoogleTokenValidator googleTokenValidator) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.emailService = emailService;
        this.googleTokenValidator = googleTokenValidator;
    }

    // ========== EMAIL/PASSWORD REGISTER ==========
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // 1. Check if email already exists
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email already registered");
        }

        // 2. Generate verification token
        String verificationToken = UUID.randomUUID().toString();

        // 3. Create user
        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .provider(AuthProvider.EMAIL)
                .emailVerified(false)
                .verificationToken(verificationToken)
                .verificationTokenExpiresAt(LocalDateTime.now().plusHours(tokenExpirationHours))
                .isActive(true)
                .build();

        // 4. Save user
        userRepository.save(user);

        // 5. Send verification email
        try {
            emailService.sendVerificationEmail(user);
        } catch (Exception e) {
            // Log error but don't fail registration
            System.err.println("Failed to send verification email: " + e.getMessage());
        }

        // 6. Return tokens (user can still login, but will be blocked later)
        return generateAuthResponse(user);
    }

    // ========== EMAIL/PASSWORD LOGIN ==========
    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        // 1. Check password (only for EMAIL provider users)
        if (user.getProvider() != AuthProvider.EMAIL) {
            throw new RuntimeException("Please login with " + user.getProvider());
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Invalid credentials");
        }

        // 2. Check if email is verified
        if (!user.isEmailVerified()) {
            throw new RuntimeException("Please verify your email before logging in. Check your inbox.");
        }

        // 3. Update last login
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        return generateAuthResponse(user);
    }

    // ========== EMAIL VERIFICATION ==========
    @Transactional
    public void verifyEmail(String token) {
        User user = userRepository.findByVerificationToken(token)
                .orElseThrow(() -> new RuntimeException("Invalid verification token"));

        if (user.isVerificationTokenExpired()) {
            throw new RuntimeException("Verification token has expired. Please request a new one.");
        }

        user.setEmailVerified(true);
        user.setVerificationToken(null);
        user.setVerificationTokenExpiresAt(null);
        userRepository.save(user);
    }

    // ========== RESEND VERIFICATION EMAIL ==========
    @Transactional
    public void resendVerificationEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.isEmailVerified()) {
            throw new RuntimeException("Email already verified");
        }

        String newToken = UUID.randomUUID().toString();
        user.setVerificationToken(newToken);
        user.setVerificationTokenExpiresAt(LocalDateTime.now().plusHours(tokenExpirationHours));
        userRepository.save(user);

        emailService.sendVerificationEmail(user);
    }

    // ========== GOOGLE LOGIN ==========
    @Transactional
    public AuthResponse loginWithGoogle(String idTokenString) {
        try {
            GoogleIdToken.Payload payload = googleTokenValidator.validateToken(idTokenString);

            String email = payload.getEmail();
            String googleId = payload.getSubject();
            String fullName = (String) payload.get("name");
            String pictureUrl = (String) payload.get("picture");

            // Check if user exists by providerId
            Optional<User> existingUser = userRepository.findByProviderId(googleId);

            if (existingUser.isPresent()) {
                User user = existingUser.get();
                user.setLastLoginAt(LocalDateTime.now());
                userRepository.save(user);
                return generateAuthResponse(user);
            }

            // Check if email already exists (could be from email/password registration)
            Optional<User> userByEmail = userRepository.findByEmail(email);
            if (userByEmail.isPresent()) {
                // Link Google account to existing email user
                User user = userByEmail.get();
                user.setProvider(AuthProvider.GOOGLE);
                user.setProviderId(googleId);
                user.setProfilePictureUrl(pictureUrl);
                user.setLastLoginAt(LocalDateTime.now());
                userRepository.save(user);
                return generateAuthResponse(user);
            }

            // Create new Google user
            User newUser = User.builder()
                    .email(email)
                    .fullName(fullName)
                    .profilePictureUrl(pictureUrl)
                    .provider(AuthProvider.GOOGLE)
                    .providerId(googleId)
                    .emailVerified(true) // Google emails are pre-verified
                    .isActive(true)
                    .lastLoginAt(LocalDateTime.now())
                    .build();

            userRepository.save(newUser);
            return generateAuthResponse(newUser);

        } catch (Exception e) {
            throw new RuntimeException("Invalid Google token: " + e.getMessage());
        }
    }

    // ========== HELPER METHODS ==========
    private AuthResponse generateAuthResponse(User user) {
        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);
        return new AuthResponse(accessToken, refreshToken);
    }
}