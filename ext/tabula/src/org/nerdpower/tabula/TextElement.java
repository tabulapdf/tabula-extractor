package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;

import org.apache.pdfbox.pdmodel.font.PDFont;

@SuppressWarnings("serial")
public class TextElement extends Rectangle2D.Float implements Comparable<TextElement> {
	
	private String text;
	private PDFont font;
	private float fontSize, widthOfSpace, dir;
	
	public TextElement(float y, float x, float width, float height,
	           PDFont font, float fontSize, String c, float widthOfSpace) {
		super();
		this.setRect(x, y, width, height);
		this.text = c;
		this.widthOfSpace = widthOfSpace;
		this.fontSize = fontSize;
	} 

	public TextElement(float y, float x, float width, float height,
			           PDFont font, float fontSize, String c, float widthOfSpace, float dir) {
		super();
		this.setRect(x, y, width, height);
		this.text = c;
		this.widthOfSpace = widthOfSpace;
		this.fontSize = fontSize;
		this.dir = dir;
	}

	public String getText() {
		return text;
	}
	
	public float getDirection() {
		return dir;
	}
	
	public float getWidthOfSpace() {
		return widthOfSpace;
	}
	
	public PDFont getFont() {
		return font;
	}
	
	public float getFontSize() {
		return fontSize;
	}

	@Override
	public int compareTo(TextElement other) {
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

}
