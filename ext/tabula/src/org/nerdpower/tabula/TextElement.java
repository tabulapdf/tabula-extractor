package org.nerdpower.tabula;

import java.util.ArrayList;
import java.util.List;

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
    
    public static List<TextChunk> mergeWords(List<TextElement> textElements) {
        return mergeWords(textElements, new ArrayList<Ruling>());
    }
    
    /**
     * heuristically merge a list of TextElement into a list of TextChunk
     * lots of ideas taken from PDFBox's PDFTextStripper.writePage
     * here be dragons
     * 
     * @param textElements
     * @param verticalRulingLocations
     * @return
     */
    public static List<TextChunk> mergeWords(List<TextElement> textElements, List<Ruling> verticalRulings) {
        
        List<TextChunk> textChunks = new ArrayList<TextChunk>();
        
        if (textElements.size() == 0) {
            return textChunks;
        }
        
        TextChunk firstTC = new TextChunk(textElements.remove(0)); 
        textChunks.add(firstTC);
        
        float previousAveCharWidth = (float) firstTC.getWidth();
        float endOfLastTextX = (float) firstTC.getRight();
        float maxYForLine = (float) firstTC.getBottom();
        float maxHeightForLine = (float) firstTC.getHeight();
        float minYTopForLine = (float) firstTC.getTop();
        float lastWordSpacing = -1;
        float wordSpacing, deltaSpace, averageCharWidth, deltaCharWidth;
        float expectedStartOfNextWordX, dist;
        TextElement sp, prevChar;
        TextChunk currentChunk;
        boolean sameLine, acrossVerticalRuling;
        
        for (TextElement chr : textElements) {
            currentChunk = textChunks.get(textChunks.size() - 1);
            prevChar = currentChunk.textElements.get(currentChunk.textElements.size() - 1);
            
            // if same char AND overlapped, skip
            if ((chr.getText() == prevChar.getText()) && (prevChar.overlapRatio(chr) > 0.5)) {
                continue;
            }
            
            // if chr is a space that overlaps with prevChar, skip
            if (chr.getText() == " " && prevChar.x == chr.x && prevChar.y == chr.y) {
                continue;
            }
            
            // Resets the average character width when we see a change in font
            // or a change in the font size
            if ((chr.getFont() != prevChar.getFont()) || (chr.getFontSize() != prevChar.getFontSize())) {
                previousAveCharWidth = -1;
            }

            // is there any vertical ruling that goes across chr and prevChar?
            acrossVerticalRuling = false;
            for (Ruling r: verticalRulings) {
                if (prevChar.x < r.getLeft() && chr.x > r.getLeft()) {
                    acrossVerticalRuling = true;
                    break;
                }
            } 
            
            // Estimate the expected width of the space based on the
            // space character with some margin.
            wordSpacing = (float) chr.getWidthOfSpace();
            deltaSpace = 0;
            if (wordSpacing == java.lang.Float.NaN || wordSpacing == 0) {
                deltaSpace = java.lang.Float.MAX_VALUE;
            }
            else if (lastWordSpacing < 0) {
                deltaSpace = wordSpacing * 0.5f; // 0.5 == spacing tolerance
            }
            else {
                deltaSpace = ((wordSpacing + lastWordSpacing) / 2.0f) * 0.5f;
            }
            
            // Estimate the expected width of the space based on the
            // average character width with some margin. This calculation does not
            // make a true average (average of averages) but we found that it gave the
            // best results after numerous experiments. Based on experiments we also found that
            // .3 worked well.
            if (previousAveCharWidth < 0) {
                averageCharWidth = (float) (chr.getWidth() / chr.getText().length());
            }
            else {
                averageCharWidth = (float) ((previousAveCharWidth + (chr.getWidth() / chr.getText().length())) / 2.0f);
            }
            deltaCharWidth = averageCharWidth * 0.3f; // 0.3 == average char tolerance
            
            // Compares the values obtained by the average method and the wordSpacing method and picks
            // the smaller number.
            expectedStartOfNextWordX = -java.lang.Float.MAX_VALUE;
            
            if (endOfLastTextX != -1) {
                expectedStartOfNextWordX = endOfLastTextX + Math.min(deltaCharWidth, deltaSpace);
            }
            
            // new line?
            sameLine = true;
            if (!overlap((float) chr.getBottom(), chr.height, maxYForLine, maxHeightForLine)) {
                endOfLastTextX = -1;
                expectedStartOfNextWordX = -java.lang.Float.MAX_VALUE;
                maxYForLine = -java.lang.Float.MAX_VALUE;
                maxHeightForLine = -1;
                minYTopForLine = java.lang.Float.MAX_VALUE;
                sameLine = false;
            }
            
            endOfLastTextX = (float) chr.getRight();
            
            // should we add a space?
            // TODO: add !accross_vertical_ruling &&
            
            if (!acrossVerticalRuling &&
                sameLine &&
                expectedStartOfNextWordX < chr.getLeft() && 
                !prevChar.getText().endsWith(" ")) {
                
//                System.out.println("Adding space");
//                System.out.println(prevChar.getText());
//                System.out.println(chr.getText());
                
                sp = new TextElement((float) prevChar.getTop(),
                        (float) prevChar.getLeft(),
                        expectedStartOfNextWordX - prevChar.x,
                        (float) prevChar.getHeight(),
                        prevChar.getFont(),
                        prevChar.getFontSize(),
                        " ",
                        prevChar.getWidthOfSpace());
                currentChunk.add(sp);
            }
            else {
                sp = null;
            }
            
            maxYForLine = (float) Math.max(chr.getBottom(), maxYForLine);
            maxHeightForLine = Math.max(maxHeightForLine, chr.height);
            minYTopForLine = Math.min(minYTopForLine, chr.y);

            dist = chr.x - (sp != null ? sp.x : prevChar.x);

            if (!acrossVerticalRuling &&
                sameLine &&
                (dist < 0 ? currentChunk.verticallyOverlaps(chr) : dist < wordSpacing)) {
                currentChunk.add(chr);
            }
            else { // create a new chunk
               textChunks.add(new TextChunk(chr));
            }
            
            lastWordSpacing = wordSpacing;
            previousAveCharWidth = sp != null ? (averageCharWidth + sp.width) / 2.0f : averageCharWidth;
        }
        return textChunks;
    }
    
    private static boolean within(float first, float second, float variance) {
        return second < first + variance && second > first - variance;
    }
    
    private static boolean overlap(float y1, float height1, float y2, float height2, float variance) {
        return within( y1, y2, variance) || (y2 <= y1 && y2 >= y1 - height1) || (y1 <= y2 && y1 >= y2-height2);
    }
    
    private static boolean overlap(float y1, float height1, float y2, float height2) {
        return overlap(y1, height1, y2, height2, 0.1f);
    }

}
