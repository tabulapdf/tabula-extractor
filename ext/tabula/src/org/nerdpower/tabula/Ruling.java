package org.nerdpower.tabula;

import java.awt.geom.Line2D;
import java.awt.geom.Point2D;
import java.awt.geom.Rectangle2D;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

@SuppressWarnings("serial")
public class Ruling extends Line2D.Float {
    
    private static int PERPENDICULAR_PIXEL_EXPAND_AMOUNT = 2;
    private static int COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT = 1;

    public Ruling(float top, float left, float width, float height) {
        super(left, top, left+width, top+height);
    }
    
    public Ruling(Point2D p1, Point2D p2) {
        super(p1, p2);
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
    
    // attributes that make sense only for non-oblique lines
    // these are used to have a single collapse method (in page, currently)
    
    public float getPosition() {
        if (this.oblique()) {
            throw new UnsupportedOperationException();
        }
        return this.vertical() ? this.getLeft() : this.getTop();
    }
    
    public void setPosition(float v) {
        if (this.oblique()) {
            throw new UnsupportedOperationException();
        }
        if (this.vertical()) {
            this.setLeft(v);
            this.setRight(v);
        }
        else {
            this.setTop(v);
            this.setBottom(v);
        }
    }
    
    public float getStart() {
        if (this.oblique()) {
            throw new UnsupportedOperationException();
        }
        return this.vertical() ? this.getTop() : this.getLeft();
    }
    
    public void setStart(float v) {
        if (this.oblique()) {
            throw new UnsupportedOperationException();
        }
        if (this.vertical()) {
            this.setTop(v);
        }
        else {
            this.setLeft(v);
        }
    }
    
    public float getEnd() {
        if (this.oblique()) {
            throw new UnsupportedOperationException();
        }
        return this.vertical() ? this.getBottom() : this.getRight();
    }
    
    public void setEnd(float v) {
        if (this.oblique()) {
            throw new UnsupportedOperationException();
        }
        if (this.vertical()) {
            this.setBottom(v);
        }
        else {
            this.setRight(v);
        }
    }
    
    // -----
        
    public boolean perpendicularTo(Ruling other) {
        return this.vertical() == other.horizontal();
    }
    
    public boolean colinear(Point2D point) {
        return point.getX() >= this.getX1()
                && point.getX() <= this.getX2()
                && point.getY() >= this.getY1()
                && point.getY() <= this.getY2();
    }
    
    // if the lines we're comparing are colinear or parallel, we expand them by a only 1 pixel,
    // because the expansions are additive
    // (e.g. two vertical lines, at x = 100, with one having y2 of 98 and the other having y1 of 102 would
    // erroneously be said to nearlyIntersect if they were each expanded by 2 (since they'd both terminate at 100).
    // The COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT is only 1 so the total expansion is 2.
    // A total expansion amount of 2 is empirically verified to work sometimes. It's not a magic number from any
    // source other than a little bit of experience.)
    public boolean nearlyIntersects(Ruling another) {
        if (this.intersectsLine(another)) {
            return true;
        }
        
        boolean rv = false;
        
        if (this.perpendicularTo(another)) {
            rv = this.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT).intersectsLine(another);
        }
        else {
            rv = this.expand(COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT)
                    .intersectsLine(another.expand(COLINEAR_OR_PARALLEL_PIXEL_EXPAND_AMOUNT));
        }
        
        return rv;
    }
    
    public double length() {
        return Math.sqrt(Math.pow(this.getX1() - this.getX2(), 2) + Math.pow(this.getY1() - this.getY2(), 2));
    }
    
    public Ruling intersect(Rectangle2D clip) {
        Line2D.Float clipee = (Line2D.Float) this.clone();
        boolean clipped = new CohenSutherlandClipping(clip).clip(clipee);

        if (clipped) {
            return new Ruling(clipee.getP1(), clipee.getP2());
        }
        else {
            return this;
        }
    }
    
    public Ruling expand(float amount) {
        Ruling r = (Ruling) this.clone();
        r.setStart(this.getStart() - amount);
        r.setEnd(this.getEnd() + amount);
        return r;
    }
    
    public Point2D intersectionPoint(Ruling other) {
        Ruling this_l = this.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT);
        Ruling other_l = other.expand(PERPENDICULAR_PIXEL_EXPAND_AMOUNT);
        Ruling horizontal, vertical;
        
        if (!this_l.intersectsLine(other_l)) {
            return null;
        }
        
        if (this_l.horizontal() && other_l.vertical()) {
            horizontal = this_l; vertical = other_l;
        }
        else if (this_l.vertical() && other_l.horizontal()) {
            vertical = this_l; horizontal = other_l;
        }
        else {
            throw new IllegalArgumentException("lines must be orthogonal, vertical and horizontal");
        }
        return new Point2D.Float(vertical.getLeft(), horizontal.getTop());        
    }
    
    public float getTop() {
        return (float) this.getY1();
    }
    
    public void setTop(float v) {
        setLine(this.getLeft(), v, this.getRight(), this.getBottom());
    }
    
    public float getLeft() {
        return (float) this.getX1();
    }
    
    public void setLeft(float v) {
        setLine(v, this.getTop(), this.getRight(), this.getBottom());
    }
    
    public float getBottom() {
        return (float) this.getY2();
    }
    
    public void setBottom(float v) {
        setLine(this.getLeft(), this.getTop(), this.getRight(), v);
    }

    public float getRight() {
        return (float) this.getX2();
    }
    
    public void setRight(float v) {
        setLine(this.getLeft(), this.getTop(), v, this.getBottom());
    }
    
    public static List<Ruling> cropRulingsToArea(List<Ruling> rulings, Rectangle2D area) {
        ArrayList<Ruling> rv = new ArrayList<Ruling>();
        for (Ruling r : rulings) {
            if (r.intersects(area)) {
                rv.add(r.intersect(area));
            }
        }
        return rv;
    }
    
    public static List<Ruling> collapseOrientedRulings(List<Ruling> lines) {
        ArrayList<Ruling> rv = new ArrayList<Ruling>();
        if (lines.size() == 0) {
            return rv;
        }
        Collections.sort(lines, new Comparator<Ruling>() {
            @Override
            public int compare(Ruling a, Ruling b) {
                return (int) (a.getPosition() != b.getPosition() ? a.getPosition() - b.getPosition() : a.getStart() - b.getStart());
            }
        });
        
        rv.add(lines.remove(0));
        for (Ruling next_line : lines) {
            Ruling last = rv.get(rv.size() - 1);
            // if current line colinear with next, and are "close enough": expand current line
            if (next_line.getPosition() == last.getPosition() && last.nearlyIntersects(next_line)) {
                last.setStart(next_line.getStart() < last.getStart() ? next_line.getStart() : last.getStart());
                last.setEnd(next_line.getEnd() < last.getEnd() ? last.getEnd() : next_line.getEnd());
            }
            else if (next_line.length() == 0) {
                continue;
            }
            else {
                rv.add(next_line);
            }
        }
        return rv;
    }
}
