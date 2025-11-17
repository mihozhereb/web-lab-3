package ru.mihozhereb;

import java.time.LocalDateTime;
import java.util.Date;

public class PointRecord {
    private final double x;
    private final double y;
    private final int r;
    private final boolean hit;
    private final LocalDateTime time;
    private final long timingMs;

    public PointRecord(double x, double y, int r, boolean hit,
                       LocalDateTime time, long timingMs) {
        this.x = x;
        this.y = y;
        this.r = r;
        this.hit = hit;
        this.time = time;
        this.timingMs = timingMs;
    }

    public double getX()      { return x; }
    public double getY()      { return y; }
    public int getR()         { return r; }
    public boolean isHit()    { return hit; }
    public LocalDateTime getTime()  { return time; }
    public long getTimingMs()       { return timingMs; }

    public Date getTimeAsDate() {
        return java.sql.Timestamp.valueOf(time);
    }
}
