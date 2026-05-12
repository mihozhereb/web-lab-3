package ru.mihozhereb;

import org.junit.jupiter.api.Test;
import sun.misc.Unsafe;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.*;

class AreaBeanTest {

    private AreaBean createAreaBeanWithoutConstructor() throws Exception {
        Field field = Unsafe.class.getDeclaredField("theUnsafe");
        field.setAccessible(true);

        Unsafe unsafe = (Unsafe) field.get(null);

        return (AreaBean) unsafe.allocateInstance(AreaBean.class);
    }

    private boolean isHit(double x, double y, int r) throws Exception {
        AreaBean areaBean = createAreaBeanWithoutConstructor();

        Method method = AreaBean.class.getDeclaredMethod(
                "isHit",
                double.class,
                double.class,
                int.class
        );

        method.setAccessible(true);

        return (boolean) method.invoke(areaBean, x, y, r);
    }

    @Test
    void shouldHitCenterPoint() throws Exception {
        assertTrue(isHit(0, 0, 2));
    }

    @Test
    void shouldHitRectangleArea() throws Exception {
        assertTrue(isHit(-1, -0.5, 2));
        assertTrue(isHit(-2, -1, 2));
    }

    @Test
    void shouldNotHitOutsideRectangleArea() throws Exception {
        assertFalse(isHit(-2.1, -0.5, 2));
        assertFalse(isHit(-1, -1.1, 2));
    }

    @Test
    void shouldHitCircleSectorArea() throws Exception {
        assertTrue(isHit(-0.5, 0.5, 2));
        assertTrue(isHit(-1, 0, 2));
    }

    @Test
    void shouldNotHitOutsideCircleSectorArea() throws Exception {
        assertFalse(isHit(-1, 1, 2));
        assertFalse(isHit(-1.1, 1.1, 2));
    }

    @Test
    void shouldHitTriangleArea() throws Exception {
        assertTrue(isHit(1, 1, 2));
        assertTrue(isHit(2, 0, 2));
        assertTrue(isHit(0, 2, 2));
    }

    @Test
    void shouldNotHitOutsideTriangleArea() throws Exception {
        assertFalse(isHit(1.5, 1, 2));
        assertFalse(isHit(1, -1, 2));
    }

    @Test
    void shouldNotHitUnsupportedQuadrants() throws Exception {
        assertFalse(isHit(1, -1, 2));
        assertFalse(isHit(-1, 1.5, 2));
    }
}