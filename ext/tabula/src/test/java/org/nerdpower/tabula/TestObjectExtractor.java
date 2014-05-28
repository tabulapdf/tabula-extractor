package org.nerdpower.tabula;

import static org.junit.Assert.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

public class TestObjectExtractor {

    @Test(expected=IOException.class)
    public void testWrongPasswordRaisesException() throws IOException {
        PDDocument pdf_document = PDDocument.load("src/test/resources/org/nerdpower/tabula/encrypted.pdf");
        ObjectExtractor oe = new ObjectExtractor(pdf_document, "wrongpass"); 
        oe.extract().next();
    }
    
    @Test(expected=IOException.class)
    public void testEmptyOnEncryptedFileRaisesException() throws IOException {
        PDDocument pdf_document = PDDocument.load("src/test/resources/org/nerdpower/tabula/encrypted.pdf");
        ObjectExtractor oe = new ObjectExtractor(pdf_document); 
        oe.extract().next();
    }
    
    @Test
    public void testGoodPassword() throws IOException {
        PDDocument pdf_document = PDDocument.load("src/test/resources/org/nerdpower/tabula/encrypted.pdf");
        ObjectExtractor oe = new ObjectExtractor(pdf_document, "userpassword"); 
        List<Page> pages = new ArrayList<Page>();
        PageIterator pi = oe.extract();
        while (pi.hasNext()) {
            pages.add(pi.next());
        }
        assertEquals(1, pages.size());
    }
    
    
}
