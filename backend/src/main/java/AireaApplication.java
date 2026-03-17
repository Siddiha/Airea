
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

import io.github.cdimascio.dotenv.Dotenv;

import java.net.URI;

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
        String[] envVars = {
            "SUPABASE_URL", "SUPABASE_USERNAME", "SUPABASE_PASSWORD",
            "SPRING_DATASOURCE_URL", "SPRING_DATASOURCE_USERNAME", "SPRING_DATASOURCE_PASSWORD",
            "DATABASE_URL", "PGUSER", "PGPASSWORD", "PORT", "CORS_ALLOWED_ORIGINS"
        };
        for (String envVar : envVars) {
            String value = System.getenv(envVar);
            if (value != null && System.getProperty(envVar) == null) {
                System.setProperty(envVar, value);
            }
        }

        normalizeDatabaseConfig();
        normalizeServerPort();

        // Start Spring Boot application
        SpringApplication.run(AireaApplication.class, args);

        System.out.println("🚀 Airea Backend Server Started Successfully!");
        System.out.println("📡 API Available at: http://localhost:8080/api");
        System.out.println("❤️  Health Check: http://localhost:8080/api/cough/health");
        System.out.println("❤️  Health Check: http://localhost:8080/api/vitals/event");
        System.out.println("🔒 Using environment variables for database connection");
    }

    private static void normalizeDatabaseConfig() {
        String currentDatasourceUrl = readPropertyOrEnv("spring.datasource.url", "SPRING_DATASOURCE_URL");
        if (isBlank(currentDatasourceUrl)) {
            String rawDatabaseUrl = firstNonBlank(
                    System.getenv("DATABASE_URL"),
                    System.getenv("SUPABASE_URL")
            );
            if (!isBlank(rawDatabaseUrl)) {
                String jdbcUrl = rawDatabaseUrl.startsWith("jdbc:")
                        ? rawDatabaseUrl
                        : "jdbc:" + rawDatabaseUrl;
                System.setProperty("spring.datasource.url", jdbcUrl);
                extractCredentialsFromDatabaseUrl(rawDatabaseUrl);
            }
        }

        if (isBlank(readPropertyOrEnv("spring.datasource.username", "SPRING_DATASOURCE_USERNAME"))) {
            String username = firstNonBlank(System.getenv("SUPABASE_USERNAME"), System.getenv("PGUSER"));
            if (!isBlank(username)) {
                System.setProperty("spring.datasource.username", username);
            }
        }

        if (isBlank(readPropertyOrEnv("spring.datasource.password", "SPRING_DATASOURCE_PASSWORD"))) {
            String password = firstNonBlank(System.getenv("SUPABASE_PASSWORD"), System.getenv("PGPASSWORD"));
            if (!isBlank(password)) {
                System.setProperty("spring.datasource.password", password);
            }
        }
    }

    private static void extractCredentialsFromDatabaseUrl(String rawDatabaseUrl) {
        try {
            URI uri = URI.create(rawDatabaseUrl);
            String userInfo = uri.getUserInfo();
            if (isBlank(userInfo)) {
                return;
            }

            String[] credentials = userInfo.split(":", 2);
            if (credentials.length > 0 && isBlank(readPropertyOrEnv("spring.datasource.username", "SPRING_DATASOURCE_USERNAME"))) {
                System.setProperty("spring.datasource.username", credentials[0]);
            }
            if (credentials.length > 1 && isBlank(readPropertyOrEnv("spring.datasource.password", "SPRING_DATASOURCE_PASSWORD"))) {
                System.setProperty("spring.datasource.password", credentials[1]);
            }
        } catch (Exception ignored) {
            // Ignore parsing issues; explicit env vars can still provide credentials.
        }
    }

    private static void normalizeServerPort() {
        String currentServerPort = System.getProperty("server.port");
        if (isBlank(currentServerPort)) {
            String port = System.getenv("PORT");
            if (!isBlank(port)) {
                System.setProperty("server.port", port);
            }
        }
    }

    private static String readPropertyOrEnv(String propertyName, String envName) {
        String value = System.getProperty(propertyName);
        if (!isBlank(value)) {
            return value;
        }
        return System.getenv(envName);
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
