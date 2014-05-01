package org.nerdpower.tabula;

import java.awt.geom.Line2D;
import java.awt.geom.Point2D;

@SuppressWarnings("serial")
public class Ruling extends Line2D.Float {

    public Ruling(float top, float left, float width, float height) {
        super(left, top, left+width, top+height);
    }

    public boolean vertical() {
        return this.getX1() == this.getX2();
    }
    
    public boolean horizontal() {
        return this.getY1() == this.getY2();
    }
    
    public boolean oblique() {
        return !(this.vertical() || this.horizontal());
    }
    
    public boolean perpendicularTo(Ruling other) {
        return this.vertical() == other.horizontal();
    }
    
    public boolean colinear(Point2D point) {
        return point.getX() >= this.getX1()
                && point.getX() <= this.getX2()
                && point.getY() >= this.getY1()
                && point.getY() <= this.getY2();
    }
    
    public double length() {
        return Math.sqrt(Math.pow(this.getX1() - this.getX2(), 2) + Math.pow(this.getY1() - this.getY2(), 2));
    }
    
    
    
}
