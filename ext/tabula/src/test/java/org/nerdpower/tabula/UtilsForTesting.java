package org.nerdpower.tabula;

import java.io.IOException;

import org.apache.pdfbox.pdmodel.PDDocument;

public class UtilsForTesting {
    
    public static Page getAreaFromFirstPage(String path, float top, float left, float bottom, float right) throws IOException {
        return getPage(path, 1).getArea(top, left, bottom, right);
    }
    
    public static Page getAreaFromPage(String path, int page, float top, float left, float bottom, float right) throws IOException {
        return getPage(path, page).getArea(top, left, bottom, right);
    }
    
    public static Page getPage(String path, int pageNumber) throws IOException {
        ObjectExtractor oe = null;
        try {
            PDDocument document = PDDocument
                    .load(path);
            oe = new ObjectExtractor(document);
            Page page = oe.extract(pageNumber);
            return page;
        } finally {
            oe.close();
        }
    }
    

}
