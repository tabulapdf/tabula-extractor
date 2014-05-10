package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;
import java.util.ArrayList;
import java.util.List;

@SuppressWarnings("serial")
public class Line extends Rectangle {
    
    List<TextElement> textElements = new ArrayList<TextElement>();
    
    
    public List<TextElement> getTextElements() {
        return textElements;
    }
    
    public void setTextElements(List<TextElement> textElements) {
        this.textElements = textElements;
    }

    
    

}
