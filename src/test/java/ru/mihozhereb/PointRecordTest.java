package ru.mihozhereb;

import org.junit.jupiter.api.Test;

import java.sql.Timestamp;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class PointRecordTest {

    @Test
    void shouldStorePointRecordValues() {
        LocalDateTime time = LocalDateTime.of(2026, 5, 12, 10, 30, 15);

        PointRecord record = new PointRecord(
                1.25,
                -0.5,
                3,
                true,
                time,
                12345L
        );

        assertEquals(1.25, record.getX());
        assertEquals(-0.5, record.getY());
        assertEquals(3, record.getR());
        assertTrue(record.isHit());
        assertEquals(time, record.getTime());
        assertEquals(12345L, record.getTimingMs());
    }

    @Test
    void shouldConvertLocalDateTimeToDate() {
        LocalDateTime time = LocalDateTime.of(2026, 5, 12, 10, 30, 15);

        PointRecord record = new PointRecord(
                0,
                0,
                1,
                true,
                time,
                100L
        );

        assertEquals(Timestamp.valueOf(time), record.getTimeAsDate());
    }
}