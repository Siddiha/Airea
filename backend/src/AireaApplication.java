import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@ComponentScan(basePackages = {"controller", "service", "config"})
@EnableJpaRepositories(basePackages = "repository")
@EntityScan(basePackages = "model")
public class AireaApplication {
    
    public static void main(String[] args) {
        // Load .env file
        Dotenv dotenv = Dotenv.configure()
                .ignoreIfMissing()  // Don't fail if .env is missing (for production)
                .load();
        
        // Set environment variables from .env
        dotenv.entries().forEach(entry -> {
            System.setProperty(entry.getKey(), entry.getValue());
        });
        
        // Start Spring Boot application
        SpringApplication.run(AireaApplication.class, args);
        
        System.out.println("🚀 Airea Backend Server Started Successfully!");
        System.out.println("📡 API Available at: http://localhost:8080/api");
        System.out.println("❤️  Health Check: http://localhost:8080/api/cough/health");
        System.out.println("🔒 Using environment variables for database connection");
    }
}