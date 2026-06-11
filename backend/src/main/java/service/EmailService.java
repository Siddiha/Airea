package service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void sendPasswordResetEmail(String toEmail, String otpCode) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        message.setSubject("Airea - Password Reset Code");
        message.setText(
                "Hello,\n\n" +
                "You requested a password reset for your Airea account.\n\n" +
                "Your verification code is: " + otpCode + "\n\n" +
                "This code will expire in 10 minutes.\n\n" +
                "If you did not request this, please ignore this email.\n\n" +
                "- Airea Team"
        );

        mailSender.send(message);
    }
}
