package org.nerdpower.tabula;
import java.awt.BasicStroke;
import java.awt.Image;
import java.awt.Shape;
import java.awt.geom.AffineTransform;
import java.awt.geom.Line2D;
import java.awt.geom.PathIterator;
import java.awt.geom.Point2D;
import java.awt.geom.Rectangle2D;
import java.io.IOException;

import org.apache.pdfbox.pdfviewer.PageDrawer;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.common.PDStream;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType3Font;
import org.apache.pdfbox.pdmodel.graphics.PDGraphicsState;
import org.apache.pdfbox.pdmodel.text.PDTextState;
import org.apache.pdfbox.util.TextPosition;

import java.util.AbstractList;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Pattern;


public class ObjectExtractor extends PageDrawer {

    class PointComparator implements Comparator<Point2D> {
        @Override
        public int compare(Point2D o1, Point2D o2) {
            if (o1.getY() > o2.getY()) return  1; 
            if (o1.getY() < o2.getY()) return -1; 
            if (o1.getX() > o2.getX()) return  1;
            if (o1.getX() < o2.getX()) return -1; 
            return  0;
        }
    }

    private static final Pattern printable = Pattern.compile("\\p{Print}");
    private static final char[] spaceLikeChars = {' ', '-', '1', 'i'};
    private static final String NBSP = "\u00A0";

    private BasicStroke basicStroke;	
    private float minCharWidth = Float.MAX_VALUE, minCharHeight = Float.MAX_VALUE;
    private List<TextElement> characters = new ArrayList<TextElement>();
    private List<Ruling> rulings = new ArrayList<Ruling>();
    private AffineTransform pageTransform;
    private Shape clippingPath;
    private Rectangle2D transformedClippingPathBounds;
    private Shape transformedClippingPath;
    private boolean extractRulingLines = true;
    private PDDocument pdf_document;
    private List<PDPage> pdf_document_pages;

    public ObjectExtractor(PDDocument pdf_document) throws IOException {
        super();
        this.pdf_document = pdf_document;
        this.pdf_document_pages = this.pdf_document.getDocumentCatalog().getAllPages();
    }

    Page extractPage(Integer page_number) throws IOException {

        if (page_number - 1 > this.pdf_document_pages.size() || page_number < 1) {
            throw new java.lang.IndexOutOfBoundsException("Page number does not exist");
        }

        PDPage p = this.pdf_document_pages.get(page_number - 1);
        PDStream contents = p.getContents();

        if (contents == null) {
            return null;
        }
        this.clear();

        this.drawPage(p);

        return new Page(p.findCropBox().getWidth(),
                p.findCropBox().getHeight(),
                p.findRotation(),
                page_number,
                this.characters,
                this.getRulings(),
                this.minCharWidth,
                this.minCharHeight);
    }

    Iterable<Page> extract(Iterable<Integer> pages) {

        final Iterator<Integer> pagesIterator = pages.iterator();

        return new Iterable<Page>() {

            @Override
            public Iterator<Page> iterator() {
                return new Iterator<Page>() {

                    @Override
                    public boolean hasNext() {
                        return pagesIterator.hasNext();
                    }

                    @Override
                    public Page next() {
                        try {
                            return extractPage(pagesIterator.next());
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                        return null;
                    }

                    @Override
                    public void remove() {
                        throw new UnsupportedOperationException();	
                    }

                };
            }

        };
    }

    Iterable<Page> extract() {
        return extract(range(1, this.pdf_document_pages.size() + 1));
    }


    public void close() throws IOException {
        this.pdf_document.close();
    }

    public void drawPage(PDPage p) throws IOException {
        page = p;
        PDStream contents = p.getContents(); 
        if (contents != null) {
            ensurePageSize();
            this.processStream(p, p.findResources(), contents.getStream());
        }
    }

    private void ensurePageSize() {
        if (this.pageSize == null && this.page != null) {
            PDRectangle mediaBox = this.page.findMediaBox();
            this.pageSize = mediaBox == null ? null : mediaBox.createDimension();
        }
    }

    private void clear() {
        this.characters = new ArrayList<TextElement>();
        this.rulings = new ArrayList<Ruling>();
        this.pageTransform = null;
        this.minCharWidth = Float.MAX_VALUE;
        this.minCharHeight = Float.MAX_VALUE;	
    }


    @Override
    public void drawImage(Image awtImage, AffineTransform at) {

    }

    @Override
    public void setStroke(BasicStroke basicStroke) {
        this.basicStroke = basicStroke;
    }

    @Override
    public BasicStroke getStroke() {
        return this.basicStroke;
    }

    @Override
    public void strokePath()  throws IOException {

        if (!this.extractRulingLines) {
            this.getLinePath().reset();
            return;
        }

        PathIterator pi = this.getLinePath().getPathIterator(this.pageTransform);
        float[] c = new float[6];
        int currentSegment;

        // skip paths whose first operation is not a MOVETO
        // or contains operations other than LINETO, MOVETO or CLOSE
        if ((pi.currentSegment(c) != PathIterator.SEG_MOVETO)) {
            this.getLinePath().reset();
            return;
        }
        pi.next();
        while (!pi.isDone()) {
            currentSegment = pi.currentSegment(c);
            if (currentSegment != PathIterator.SEG_LINETO &&
                    currentSegment != PathIterator.SEG_CLOSE &&
                    currentSegment != PathIterator.SEG_MOVETO) {
                this.getLinePath().reset();
                return;
            }
            pi.next();
        }

        // TODO: how to implement color filter?

        // skip the first path operation and save it as the starting position
        float[] first = new float[6];
        pi = this.getLinePath().getPathIterator(this.pageTransform);
        pi.currentSegment(first);
        // last move
        Point2D.Float start_pos = new Point2D.Float(first[0], first[1]);
        Point2D.Float last_move = start_pos;
        Point2D.Float end_pos = null;
        Line2D.Float line;
        PointComparator pc = new PointComparator();

        while (!pi.isDone()) {
            pi.next();
            currentSegment = pi.currentSegment(c);
            switch(currentSegment) {
            case PathIterator.SEG_LINETO:
                end_pos = new Point2D.Float(c[0], c[1]);

                line = pc.compare(start_pos, end_pos) == -1 ? 
                        new Line2D.Float(start_pos, end_pos) : 
                            new Line2D.Float(end_pos, start_pos); 

                        if (line.intersects(this.currentClippingPath())) {
                            Rectangle2D tmp = line.getBounds2D().createIntersection(this.currentClippingPath()).getBounds2D();
                            this.getRulings().add(new Ruling((float) tmp.getY(),
                                    (float) tmp.getX(),
                                    (float) tmp.getWidth(),
                                    (float) tmp.getHeight()));

                        }
                        break;
            case PathIterator.SEG_MOVETO:
                last_move = new Point2D.Float(c[0], c[1]); 
                break;
            case PathIterator.SEG_CLOSE:
                // according to PathIterator docs:
                // "the preceding subpath should be closed by appending a line segment
                // back to the point corresponding to the most recent SEG_MOVETO."
                line = pc.compare(end_pos, last_move) == -1 ? 
                        new Line2D.Float(end_pos, last_move) : 
                            new Line2D.Float(last_move, end_pos); 

                        if (line.intersects(this.currentClippingPath())) {
                            Rectangle2D tmp = line.getBounds2D().createIntersection(this.currentClippingPath()).getBounds2D();
                            this.getRulings().add(new Ruling((float) tmp.getY(),
                                    (float) tmp.getX(),
                                    (float) tmp.getWidth(),
                                    (float) tmp.getHeight()));
                        }
                        break;
            }
            start_pos = end_pos;
        }
        this.getLinePath().reset();
    }

    @Override
    public void fillPath(int windingRule) throws IOException {
        float[] color_comps = this.getGraphicsState().getNonStrokingColor().getJavaColor().getRGBColorComponents(null);
        // TODO use color_comps as filter_by_color
        this.strokePath();
    }


    private float currentSpaceWidth() {
        PDGraphicsState gs = this.getGraphicsState();
        PDTextState ts = gs.getTextState();
        PDFont font = ts.getFont();
        float fontSizeText = ts.getFontSize();
        double horizontalScalingText = ts.getHorizontalScalingPercent() / 100.0;
        float spaceWidthText = 1000;

        // TODO FINISH
        if (font instanceof PDType3Font) {
            // TODO WHAT?
        }

        for(int i = 0; i < spaceLikeChars.length; i++) {
            spaceWidthText = font.getFontWidth(spaceLikeChars[i]);
            if (spaceWidthText > 1000) break;
        }

        float ctm00 = gs.getCurrentTransformationMatrix().getValue(0, 0);

        return (float) ((spaceWidthText / 1000.0) * fontSizeText * horizontalScalingText * (ctm00 == 0 ? 1 : ctm00));
    }

    @Override
    protected void processTextPosition(TextPosition textPosition) {
        String c = textPosition.getCharacter();

        // if c not printable, return
        //		 if (!printable.matcher(c).matches()) {
        //			return;
        //		}

        Float  h = textPosition.getHeightDir();

        if (c == NBSP) { // replace non-breaking space for space
            c = " ";
        }

        float wos = textPosition.getWidthOfSpace();

        TextElement te = new TextElement(textPosition.getY() - h,
                textPosition.getX(),
                textPosition.getWidthDirAdj(),
                textPosition.getHeightDir(),
                textPosition.getFont(),
                textPosition.getFontSize(),
                c,
                // workaround a possible bug in PDFBox: https://issues.apache.org/jira/browse/PDFBOX-1755
                (wos == Float.NaN || wos == 0) ? this.currentSpaceWidth() : wos,
                        textPosition.getDir());

        if (this.currentClippingPath().intersects(te)) {
            this.characters.add(te);
        }		
    }

    public float getMinCharWidth() {
        return minCharWidth;
    }

    public float getMinCharHeight() {
        return minCharHeight;
    }

    public AffineTransform getPageTransform() {

        PDRectangle cb = page.findCropBox();
        int rotation = page.findRotation();

        if (rotation != 90 && rotation != -270 && rotation != -90 && rotation != 270) {
            this.pageTransform = AffineTransform.getScaleInstance(1, -1);
            this.pageTransform.translate(0, -cb.getHeight());
        }
        else {
            this.pageTransform = AffineTransform.getScaleInstance(-1, 1);
            this.pageTransform.rotate(rotation * (Math.PI/180.0),
                    cb.getLowerLeftX(), cb.getLowerLeftY());
        }
        return this.pageTransform;
    }

    public Rectangle2D currentClippingPath() {
        //		Shape cp = this.getGraphicsState().getCurrentClippingPath();
        //		if (cp == this.clippingPath) {
        //			return this.transformedClippingPathBounds;
        //		}

        this.clippingPath = this.getGraphicsState().getCurrentClippingPath();
        this.transformedClippingPath = this.getPageTransform().createTransformedShape(this.clippingPath);
        this.transformedClippingPathBounds = this.transformedClippingPath.getBounds2D();

        return this.transformedClippingPathBounds;
    }

    public boolean isExtractRulingLines() {
        return extractRulingLines;
    }

    public void setExtractRulingLines(boolean extractRulingLines) {
        this.extractRulingLines = extractRulingLines;
    }

    public List<Ruling> getRulings() {
        return rulings;
    }

    public List<TextElement> getCharacters() {
        return characters;
    }

    // range iterator
    private static List<Integer> range(final int begin, final int end) {
        return new AbstractList<Integer>() {
            @Override
            public Integer get(int index) {
                return begin + index;
            }

            @Override
            public int size() {
                return end - begin;
            }
        };
    }

    // for testing, disregard	
    //	public static void main(String[] args) throws IOException {
    //		PDDocument document = PDDocument.load(args[0]);
    //		ObjectExtractor oe = new ObjectExtractor(document);
    //		//for (Page z: oe.extractPages(new ArrayList<Integer>(Arrays.asList(1,2)))) {
    //		for (Page z: oe.extractPages()) {
    //			System.out.println(z);
    //		}
    //	}

}