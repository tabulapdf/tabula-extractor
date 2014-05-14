package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

@SuppressWarnings("serial")
public class Page extends Rectangle {

    private Integer rotation;
    private int pageNumber;
    private List<TextElement> texts;
    private List<Ruling> rulings, verticalRulingLines, horizontalRulingLines;
    private float minCharWidth;
    private float minCharHeight;
    private TextElementIndex spatial_index;

    public Page(float width, float height, Integer rotation, int page_number) {
        super();
        this.setRect(0, 0, width, height);
        this.rotation = rotation;
        this.pageNumber = page_number;
    }
    
    public Page(float width, float height, Integer rotation, int page_number,
            List<TextElement> characters, List<Ruling> rulings) {

        this(width, height, rotation, page_number);
        this.texts = characters;
        this.rulings = rulings;
    }


    public Page(float width, float height, Integer rotation, int page_number,
            List<TextElement> characters, List<Ruling> rulings,
            float minCharWidth, float minCharHeight, TextElementIndex index) {

        this(width, height, rotation, page_number, characters, rulings);
        this.minCharHeight = minCharHeight;
        this.minCharWidth = minCharWidth;
        this.spatial_index = index;
    }

    
    public Page getArea(Rectangle2D area) {
        List<TextElement> t = getText(area);
        
        return new Page((float) area.getWidth(),
                        (float) area.getHeight(),
                        rotation,
                        pageNumber,
                        t,
                        Ruling.cropRulingsToArea(getRulings(), area),

                        Collections.min(t, new Comparator<TextElement>() {
                            @Override
                            public int compare(TextElement te1, TextElement te2) {
                                return (int) Math.signum(te1.width - te2.width);
                            }}).width,
                        
                        Collections.min(t, new Comparator<TextElement>() {
                                @Override
                                public int compare(TextElement te1, TextElement te2) {
                                    return (int) Math.signum(te1.height - te2.height);
                        }}).height,
                        
                        spatial_index);
    }
    
    public Page getArea(float top, float left, float bottom, float right) {
        Rectangle2D.Float area = new Rectangle2D.Float(left, top, Math.abs(right - left), Math.abs(bottom - top));
        return this.getArea(area);
    }
    
    public List<TextElement> getText() {
        return texts;
    }
    
    public List<TextElement> getText(Rectangle2D area) {
        return this.spatial_index.contains(area);
    }
    
    public List<TextElement> getText(float top, float left, float bottom, float right) {
        Rectangle2D.Float area = new Rectangle2D.Float(left, top, Math.abs(right - left), Math.abs(bottom - top));
        return this.getText(area);
    }

    public Integer getRotation() {
        return rotation;
    }

    public int getPageNumber() {
        return pageNumber;
    }

    public List<TextElement> getTexts() {
        return texts;
    }

    public List<Ruling> getRulings() {
        return rulings;
    }
    
    public List<Ruling> getVerticalRulings() {
        if (this.verticalRulingLines != null) {
            return this.verticalRulingLines;
        }
        
        this.verticalRulingLines = new ArrayList<Ruling>();
        for (Ruling vr: this.getRulings()) {
            if (vr.vertical()) {
                this.verticalRulingLines.add(vr);
            }
        }
        return this.verticalRulingLines;
    }
    
    public List<Ruling> getHorizontalRulings() {
        if (this.horizontalRulingLines != null) {
            return this.horizontalRulingLines;
        }
        
        this.horizontalRulingLines = new ArrayList<Ruling>();
        for (Ruling hr: this.getRulings()) {
            if (hr.horizontal()) {
                this.horizontalRulingLines.add(hr);
            }
        }
        return this.horizontalRulingLines;
    }


    public float getMinCharWidth() {
        return minCharWidth;
    }

    public float getMinCharHeight() {
        return minCharHeight;
    }
    
    public TextElementIndex getSpatialIndex() {
        return this.spatial_index;
    }
}
