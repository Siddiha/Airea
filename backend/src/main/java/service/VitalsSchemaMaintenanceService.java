package service;

import jakarta.annotation.PostConstruct;
import org.springframework.dao.DataAccessException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class VitalsSchemaMaintenanceService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostConstruct
    public void ensureVitalsRrEstimatedIntegrity() {
        try {
            Integer tableExists = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'vitals_event'",
                    Integer.class
            );

            if (tableExists == null || tableExists == 0) {
                System.out.println("ℹ️ vitals_event table not found yet; skipping rr_estimated maintenance");
                return;
            }

            int updatedRows = jdbcTemplate.update(
                    "UPDATE vitals_event SET rr_estimated = FALSE WHERE rr_estimated IS NULL"
            );

            jdbcTemplate.execute("ALTER TABLE vitals_event ALTER COLUMN rr_estimated SET DEFAULT FALSE");
            jdbcTemplate.execute("ALTER TABLE vitals_event ALTER COLUMN rr_estimated SET NOT NULL");

            System.out.println("✅ rr_estimated integrity ensured (rows fixed: " + updatedRows + ")");
        } catch (DataAccessException | IllegalStateException e) {
            System.err.println("⚠️ rr_estimated maintenance skipped: " + e.getMessage());
        }
    }
}
