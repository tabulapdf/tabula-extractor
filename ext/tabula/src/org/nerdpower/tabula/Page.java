package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;
import java.util.List;

@SuppressWarnings("serial")
public class Page extends Rectangle2D.Float {

    private Integer rotation;
    private int page_number;
    private List<TextElement> texts;
    private List<Ruling> rulings;
    private float minCharWidth;
    private float minCharHeight;

    public Page(float width, float height, Integer rotation, int page_number) {
        super();
        this.setRect(0, 0, width, height);
        this.rotation = rotation;
        this.page_number = page_number;
    }

    public Page(float width, float height, Integer rotation, int page_number,
            List<TextElement> characters, List<Ruling> rulings,
            float minCharWidth, float minCharHeight) {

        super();
        this.setRect(0, 0, width, height);
        this.rotation = rotation;
        this.page_number = page_number;
        this.texts = characters;
        this.rulings = rulings;
        this.minCharHeight = minCharHeight;
        this.minCharWidth = minCharWidth;
    }

    public Page(float width, float height, Integer rotation, int page_number,
            List<TextElement> characters, List<Ruling> rulings) {

        super();
        this.setRect(0, 0, width, height);
        this.rotation = rotation;
        this.page_number = page_number;
        this.texts = characters;
        this.rulings = rulings;
    }

    public Integer getRotation() {
        return rotation;
    }

    public int getPage_number() {
        return page_number;
    }

    public List<TextElement> getTexts() {
        return texts;
    }

    public List<Ruling> getRulings() {
        return rulings;
    }

    public float getMinCharWidth() {
        return minCharWidth;
    }

    public float getMinCharHeight() {
        return minCharHeight;
    }
}
