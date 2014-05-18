package org.nerdpower.tabula;

import java.util.AbstractList;
import java.util.List;

/**
 *
 * @author manuel
 */
public class Utils {
    public static boolean within(double first, double second, double variance) {
        return second < first + variance && second > first - variance;
    }
    
    public static boolean overlap(double y1, double height1, double y2, double height2, double variance) {
        return within( y1, y2, variance) || (y2 <= y1 && y2 >= y1 - height1) || (y1 <= y2 && y1 >= y2-height2);
    }
    
    public static boolean overlap(double y1, double height1, double y2, double height2) {
        return overlap(y1, height1, y2, height2, 0.1f);
    }
    
    // range iterator
    public static List<Integer> range(final int begin, final int end) {
        return new AbstractList<Integer>() {
            @Override
            public Integer get(int index) {
                return begin + index;
            }

            @Override
            public int size() {
                return end - begin;
            }
        };
    }

}
