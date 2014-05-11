package org.nerdpower.tabula;

import java.util.ArrayList;
import java.util.List;

@SuppressWarnings("serial")
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
    
    public static List<Line> groupByLines(List<TextChunk> textChunks) {
        float bbwidth = Rectangle.boundingBoxOf(textChunks).width;
        List<Line> lines = new ArrayList<Line>();
        
        Line l = new Line();
        l.addTextChunk(textChunks.get(0));
        textChunks.remove(0);
        lines.add(l);

        Line last = lines.get(lines.size() - 1);
        for (TextChunk te: textChunks) {
            if (last.horizontalOverlapRatio(te) < 0.1) {
                if (last.width / bbwidth > 0.9 && allSameChar(last.getTextElements())) {
                    lines.remove(lines.size() - 1);
                }
                lines.add(new Line());
                last = lines.get(lines.size() - 1);
            }
            last.addTextChunk(te);
        }
        
        if (last.width / bbwidth > 0.9 && allSameChar(last.getTextElements())) {
            lines.remove(lines.size() - 1);
        }
        
        // TODO
        // implement lines.map!(&:remove_sequential_spaces!)
        
        return lines;
    }
    
    public String toString() {
        StringBuilder sb = new StringBuilder();
        String s = super.toString();
        sb.append(s.substring(0, s.length() - 1));
        sb.append(String.format(", text=\"%s\"]", this.getText()));
        return sb.toString();
    }
    
    public String getText() {
        StringBuilder sb = new StringBuilder();
        for (TextElement te: this.textElements) {
            sb.append(te.getText());
        }
        return sb.toString();
    }
    
    public static boolean allSameChar(List<TextChunk> textChunks) {
        StringBuilder sb = new StringBuilder();
        for (TextChunk tc: textChunks) {
            sb.append(tc.getText());
        }
        String s = sb.toString();
        char c = s.charAt(0);
        for (int i = 1; i < s.length(); c = s.charAt(i), i++) {
            if (c != s.charAt(i)) {
                return false;
            }
        }
        return true;
    }


}
