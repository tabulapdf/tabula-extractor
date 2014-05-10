package org.nerdpower.tabula;

import java.util.ArrayList;
import java.util.List;

public class TextChunk extends Rectangle {
    
    List<TextElement> textElements = new ArrayList<TextElement>();
    
    public TextChunk(float top, float left, float width, float height) {
        super(top, left, width, height);
    }
    
    public TextChunk(TextElement textElement) {
        super(textElement.y, textElement.x, textElement.width, textElement.height);
        this.textElements.add(textElement);
    }
    
    public TextChunk merge(TextChunk other) {
        if (this.compareTo(other) < 0) {
            this.textElements.addAll(other.textElements);
        }
        else {
            this.textElements.addAll(0, other.textElements);
        }
        super.merge(other);
        return this;

    }
    
    public void add(TextElement textElement) {
        this.textElements.add(textElement);
        this.merge(textElement);
    }

    public List<TextElement> getTextElements() {
        return textElements;
    }


}
