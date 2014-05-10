package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;

public class Rectangle extends Rectangle2D.Float implements Comparable<Rectangle> {
    
    private static float SIMILARITY_DIVISOR = 20;
    
    public Rectangle() {
        super();
    }
    
    public Rectangle(float top, float left, float width, float height) {
        super();
        this.setRect(left, top, width, height);
    }

    @Override
    public int compareTo(Rectangle other) {
        double thisBottom = this.getY() + this.getHeight();
        double otherBottom = other.getY() + other.getHeight();
        double yDifference = Math.abs(thisBottom - otherBottom);
        if ((yDifference < 0.1) ||
                (otherBottom >= this.getY() && otherBottom <= thisBottom) ||
                (thisBottom >= other.getY() && thisBottom <= otherBottom)) {
            return java.lang.Double.compare(this.getX(), other.getX());
        }
        else {
            return java.lang.Double.compare(thisBottom, otherBottom);
        }
    }
    
    public float getArea() {
        return this.width * this.height;
    }
    
    public boolean verticallyOverlaps(Rectangle other) {
        return Math.max(0, Math.min(this.getBottom(), other.getBottom()) - Math.max(this.getTop(), other.getTop())) > 0;
    }
    
    public boolean horizontallyOverlaps(Rectangle other) {
        return Math.max(0, Math.min(this.getRight(), other.getRight()) - Math.max(this.getLeft(), other.getLeft())) > 0;
    }
    
    public float overlapRatio(Rectangle other) {
        double intersectionWidth = Math.max(0, Math.min(this.getRight(), other.getRight()) - Math.max(this.getLeft(), other.getLeft()));
        double intersectionHeight = Math.max(0, Math.min(this.getBottom(), other.getBottom()) - Math.max(this.getTop(), other.getTop()));
        double intersectionArea = Math.max(0, intersectionWidth * intersectionHeight);
        double unionArea = this.getArea() + other.getArea() - intersectionArea;
        
        return (float) (intersectionArea / unionArea);
    }
    
    public Rectangle merge(Rectangle other) {
        setTop(Math.min(this.getTop(), other.getTop()));
        setLeft(Math.min(this.getLeft(), other.getLeft()));
        this.width = (float) (Math.max(this.getRight(), other.getRight()) - this.getLeft());
        this.height = (float) (Math.max(this.getBottom(), other.getBottom()) - this.getTop());

        return this;
    }

    public double getTop() {
        return this.getMinY();
    }
    
    public void setTop(double top) {
        double deltaHeight = top - this.y;
        this.setRect(this.x, top, this.width, this.height - deltaHeight);
    }
    
    public double getRight() {
        return this.getMaxX();
    }
    
    public void setRight(double right) {
        this.setRect(this.x, this.y, right - this.x, this.height);
    }
        
    
    public double getLeft() {
        return this.getMinX();
    }
    
    public void setLeft(double left) {
        double deltaWidth = left - this.x;
        this.setRect(left, this.y, this.width - deltaWidth, this.height);
    }
    
    public double getBottom() {
        return this.getMaxY();
    }
    
    public void setBottom(double bottom) {
        this.setRect(this.x, this.y, this.width, bottom - this.y);
    }
    
    
}
