/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package org.nerdpower.tabula;

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

}
