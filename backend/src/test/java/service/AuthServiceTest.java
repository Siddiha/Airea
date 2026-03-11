package service;

import config.JwtUtil;
import dto.AuthResponse;
import dto.DoctorAuthResponse;
import dto.LoginRequest;
import dto.RegisterRequest;
import dto.DoctorRegisterRequest;
import model.Doctor;
import model.Patient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import repository.DoctorRepository;
import repository.PatientRepository;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AuthServiceTest {

    @Mock
    private PatientRepository patientRepository;

    @Mock
    private DoctorRepository doctorRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    private Patient testPatient;
    private Doctor testDoctor;
    private RegisterRequest patientRegRequest;
    private DoctorRegisterRequest doctorRegRequest;
    private LoginRequest loginRequest;

    @BeforeEach
    void setUp() {
        testPatient = new Patient();
        testPatient.setEmail("patient@test.com");
        testPatient.setPassword("encodedPassword");
        testPatient.setFullName("John Doe");
        testPatient.setIsActive(true);

        patientRegRequest = new RegisterRequest();
        patientRegRequest.setEmail("patient@test.com");
        patientRegRequest.setPassword("rawPassword");
        patientRegRequest.setFullName("John Doe");

        testDoctor = new Doctor();
        testDoctor.setEmail("doctor@test.com");
        testDoctor.setPassword("encodedPassword");
        testDoctor.setFullName("Dr. Smith");
        testDoctor.setIsActive(true);

        doctorRegRequest = new DoctorRegisterRequest();
        doctorRegRequest.setEmail("doctor@test.com");
        doctorRegRequest.setPassword("rawPassword");
        doctorRegRequest.setFullName("Dr. Smith");

        loginRequest = new LoginRequest();
        loginRequest.setEmail("patient@test.com");
        loginRequest.setPassword("rawPassword");
    }

    @Test
    void registerPatient_WhenEmailExists_ShouldThrowException() {
        when(patientRepository.existsByEmail("patient@test.com")).thenReturn(true);

        Exception exception = assertThrows(RuntimeException.class, () -> authService.register(patientRegRequest));
        assertEquals("Email already registered", exception.getMessage());
        verify(patientRepository, never()).save(any(Patient.class));
    }

    @Test
    void registerPatient_WhenValid_ShouldReturnAuthResponse() {
        when(patientRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode("rawPassword")).thenReturn("encodedPassword");
        when(patientRepository.save(any(Patient.class))).thenReturn(testPatient);
        when(jwtUtil.generateToken("patient@test.com")).thenReturn("mock-jwt-token");
        when(jwtUtil.getExpirationInSeconds()).thenReturn(3600L);

        AuthResponse response = authService.register(patientRegRequest);

        assertNotNull(response);
        assertEquals("mock-jwt-token", response.getToken());
        assertEquals("patient@test.com", response.getPatient().getEmail());
        verify(patientRepository).save(any(Patient.class));
    }

    @Test
    void loginPatient_WhenValidCredentials_ShouldReturnAuthResponse() {
        when(patientRepository.findByEmail("patient@test.com")).thenReturn(Optional.of(testPatient));
        when(passwordEncoder.matches("rawPassword", "encodedPassword")).thenReturn(true);
        when(jwtUtil.generateToken("patient@test.com")).thenReturn("mock-jwt-token");
        when(jwtUtil.getExpirationInSeconds()).thenReturn(3600L);

        AuthResponse response = authService.login(loginRequest);

        assertNotNull(response);
        assertEquals("mock-jwt-token", response.getToken());
    }

    @Test
    void loginPatient_WhenInvalidPassword_ShouldThrowException() {
        when(patientRepository.findByEmail("patient@test.com")).thenReturn(Optional.of(testPatient));
        when(passwordEncoder.matches("rawPassword", "encodedPassword")).thenReturn(false);

        Exception exception = assertThrows(RuntimeException.class, () -> authService.login(loginRequest));
        assertEquals("Invalid email or password", exception.getMessage());
    }

    @Test
    void loginPatient_WhenAccountInactive_ShouldThrowException() {
        testPatient.setIsActive(false);
        when(patientRepository.findByEmail("patient@test.com")).thenReturn(Optional.of(testPatient));
        when(passwordEncoder.matches("rawPassword", "encodedPassword")).thenReturn(true);

        Exception exception = assertThrows(RuntimeException.class, () -> authService.login(loginRequest));
        assertEquals("Account is deactivated", exception.getMessage());
    }

    @Test
    void doctorRegister_WhenValid_ShouldReturnDoctorAuthResponse() {
        when(doctorRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode("rawPassword")).thenReturn("encodedPassword");
        when(doctorRepository.save(any(Doctor.class))).thenReturn(testDoctor);
        when(jwtUtil.generateToken("doctor@test.com")).thenReturn("mock-doctor-jwt");
        when(jwtUtil.getExpirationInSeconds()).thenReturn(3600L);

        DoctorAuthResponse response = authService.doctorRegister(doctorRegRequest);

        assertNotNull(response);
        assertEquals("mock-doctor-jwt", response.getToken());
        assertEquals("doctor@test.com", response.getDoctor().getEmail());
        verify(doctorRepository).save(any(Doctor.class));
    }
}
