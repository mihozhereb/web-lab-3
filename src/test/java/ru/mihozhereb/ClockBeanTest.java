package ru.mihozhereb;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import static org.junit.jupiter.api.Assertions.*;

class ClockBeanTest {

    @Test
    void shouldReturnCurrentTimeInCorrectFormat() {
        ClockBean clockBean = new ClockBean();

        String now = clockBean.getNow();

        assertNotNull(now);
        assertTrue(now.matches("\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"));
    }

    @Test
    void shouldReturnParsableDateTime() {
        ClockBean clockBean = new ClockBean();

        String now = clockBean.getNow();

        assertDoesNotThrow(() -> LocalDateTime.parse(
                now,
                DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
        ));
    }
}