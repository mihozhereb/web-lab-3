package ru.mihozhereb;

import com.google.gson.Gson;
import jakarta.enterprise.context.SessionScoped;
import jakarta.inject.Named;
import jakarta.faces.context.FacesContext;
import jakarta.servlet.ServletContext;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Named
@SessionScoped
public class AreaBean implements Serializabledchjkljzdcbhlhbjcfbhhbjfd {

    @Serial
    private static final long serialVersionUID = 1L;

    private List<PointRecord> history;

    private final Gson gson = new Gson();

    private Double x;
    private Double y;
    private Integer r;

    ServletContext ctx = (ServletContext)
            FacesContext.getCurrentInstance()
                    .getExternalContext()
                    .getContext();

    private final PointsRepository repo = new PointsRepository(ctx);

    public Double getX() { return x; }
    public void setX(Double x) { this.x = x; }

    public Double getY() { return y; }
    public void setY(Double y) { this.y = y; }

    public Integer getR() { return r; }
    public void setR(Integer r) { this.r = r; }

    private void reloadHistory() {
        history = repo.findBySession(getSessionId());
    }

    public List<PointRecord> getHistory() {
        return history;
    }

    public String checkPoint() {
        if (x == null || y == null || r == null) {
            return null;
        }

        long t0 = System.nanoTime();

        boolean hit = isHit(x, y, r);

        long timingMs = (System.nanoTime() - t0);
        LocalDateTime now = LocalDateTime.now();

        PointRecord rec = new PointRecord(x, y, r, hit, now, timingMs);
        repo.save(getSessionId(), rec);

        reloadHistory();

        return null;
    }

    public String clearHistory() {
        repo.clearBySession(getSessionId());
        reloadHistory();
        return null;
    }

    private String getSessionId() {
        return FacesContext.getCurrentInstance()
                .getExternalContext()
                .getSessionId(true);
    }

    public boolean isHit(double x, double y, int r) {
        double R = r;
        double eps = 1e-9;

        boolean inCircleSector =
                x <= 0 + eps &&
                        y >= 0 - eps &&
                        (x * x + y * y <= R / 2 * R / 2 + eps);

        boolean inRectangle =
                x >= -R - eps && x <= 0 + eps &&
                        y <= 0 + eps && y >= -R / 2.0 - eps;

        boolean inTriangle =
                x >= 0 - eps && y >= 0 - eps &&
                        x <= R + eps && y <= R + eps &&
                        y <= -x + R + eps;

        return inCircleSector || inRectangle || inTriangle;
    }

    public String getPointsJson() {
        if (history == null) return "[]";

        List<Map<String, Object>> arr = new ArrayList<>();

        for (PointRecord p : history) {
            Map<String, Object> obj = new HashMap<>();
            obj.put("x", p.getX());
            obj.put("y", p.getY());
            obj.put("r", p.getR());
            obj.put("hit", p.isHit());
            obj.put("time", p.getTime().toString());
            obj.put("timing", p.getTimingMs());
            arr.add(obj);
        }

        return gson.toJson(arr);
    }
}