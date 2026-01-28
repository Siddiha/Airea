
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

import io.github.cdimascio.dotenv.Dotenv;

@SpringBootApplication
@ComponentScan(basePackages = {"controller", "service", "config", "dto"})
@EnableJpaRepositories(basePackages = "repository")
@EntityScan(basePackages = "model")
@EnableScheduling
public class AireaApplication {

    public static void main(String[] args) {
        // Load .env file for local development
        Dotenv dotenv = Dotenv.configure()
                .ignoreIfMissing() // Don't fail if .env is missing (for production)
                .load();

        // Set environment variables from .env file
        dotenv.entries().forEach(entry -> {
            System.setProperty(entry.getKey(), entry.getValue());
        });

        // For production (Railway/Docker): Also check OS environment variables
        // This ensures Railway's env vars are available to Spring
        String[] envVars = {"SUPABASE_URL", "SUPABASE_USERNAME", "SUPABASE_PASSWORD", "PORT", "CORS_ALLOWED_ORIGINS"};
        for (String envVar : envVars) {
            String value = System.getenv(envVar);
            if (value != null && System.getProperty(envVar) == null) {
                System.setProperty(envVar, value);
            }
        }

        // Start Spring Boot application
        SpringApplication.run(AireaApplication.class, args);

        System.out.println("🚀 Airea Backend Server Started Successfully!");
        System.out.println("📡 API Available at: http://localhost:8080/api");
        System.out.println("❤️  Health Check: http://localhost:8080/api/cough/health");
        System.out.println("🔒 Using environment variables for database connection");
    }
}
