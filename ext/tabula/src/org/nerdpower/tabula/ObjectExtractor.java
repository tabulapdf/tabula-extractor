package org.nerdpower.tabula;
import java.awt.BasicStroke;
import java.io.IOException;

import org.apache.pdfbox.pdfviewer.PageDrawer;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.util.TextPosition;


public class ObjectExtractor extends PageDrawer {

	public ObjectExtractor(String pdf_filename) throws IOException {
		super();
		// TODO Auto-generated constructor stub
	}
	
	
	void drawPage(PDPage p) {
		
	}
	
	@Override
	public void setStroke(BasicStroke basicStroke) {
		
	}
	
	@Override
	public BasicStroke getStroke() {
		return null;	
	}
	
	@Override
	public void strokePath()  throws IOException {
		
	}
	
	@Override
    protected void processTextPosition(TextPosition textPosition) {
		
	}

}
