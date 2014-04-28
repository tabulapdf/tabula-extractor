package org.nerdpower.tabula;
import java.awt.BasicStroke;
import java.awt.geom.AffineTransform;
import java.io.IOException;

import org.apache.pdfbox.pdfviewer.PageDrawer;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.util.TextPosition;

import com.sun.medialib.mlib.Image;

import java.util.ArrayList;
import java.util.regex.MatchResult;
import java.util.regex.Pattern;


public class ObjectExtractor extends PageDrawer {


	private static final Pattern printable = Pattern.compile("\\p{Print}");
	
	private BasicStroke basicStroke;	
	private float minCharWidth, maxCharWidth;
	private ArrayList<TextElement> characters = new ArrayList<TextElement>();
	
	
	public ObjectExtractor(String pdf_filename) throws IOException {
		super();
		// TODO Auto-generated constructor stub
	}
	
	@Override
	void drawPage(PDPage p) {
		
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
		
	}
	
	private float currentSpaceWidth() {
		
		return 0;
	}
	
	@Override
    protected void processTextPosition(TextPosition textPosition) {
		String c = textPosition.getCharacter();
		
		// if c not printable, return
		if (!printable.matcher(c).matches()) {
			return;
		}
		
		Float  h = textPosition.getHeightDir();
		
		if (c == "Ê") { // replace non-breaking space for space
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
		
		
		
	}


	public float getMaxCharWidth() {
		return maxCharWidth;
	}

	public float getMinCharWidth() {
		return minCharWidth;
	}


}