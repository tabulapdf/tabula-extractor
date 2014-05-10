package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;

import org.apache.pdfbox.pdmodel.font.PDFont;

@SuppressWarnings("serial")
public class TextElement extends Rectangle  {

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
    

}
