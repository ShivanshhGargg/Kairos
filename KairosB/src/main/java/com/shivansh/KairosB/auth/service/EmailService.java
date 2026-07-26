package com.shivansh.KairosB.auth.service;

import com.shivansh.KairosB.auth.model.User;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.frontend-url}")
    private String frontendUrl;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendVerificationEmail(User user) {
        String verificationLink = frontendUrl + "/verify?token=" + user.getVerificationToken();

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(user.getEmail());
        message.setSubject("Welcome to Kairos! Verify your email");
        message.setText("""
                Hello %s,
                
                Please verify your email address by clicking the link below:
                %s
                
                This link will expire in 24 hours.
                
                If you did not create an account, please ignore this email.
                
                Best,
                The Kairos Team
                """.formatted(user.getFullName(), verificationLink));

        mailSender.send(message);
    }
}