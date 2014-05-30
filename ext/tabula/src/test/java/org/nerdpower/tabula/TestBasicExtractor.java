package org.nerdpower.tabula;

import static org.junit.Assert.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.junit.Test;
import org.nerdpower.tabula.Page;
import org.nerdpower.tabula.Ruling;
import org.nerdpower.tabula.Table;
import org.nerdpower.tabula.extractors.BasicExtractionAlgorithm;
import org.nerdpower.tabula.extractors.SpreadsheetExtractionAlgorithm;
import org.nerdpower.tabula.writers.CSVWriter;


public class TestBasicExtractor {

    @Test
    public void testRemoveSequentialSpaces() throws IOException {
        Page page = UtilsForTesting.getAreaFromFirstPage(
                "src/test/resources/org/nerdpower/tabula/m27.pdf", 79.2f,
                28.28f, 103.04f, 732.6f);
        BasicExtractionAlgorithm bea = new BasicExtractionAlgorithm();
        Table table = bea.extract(page).get(0);
        List<RectangularTextContainer> firstRow = table.getRows().get(0);

        assertTrue(firstRow.get(2).getText().equals("ALLEGIANT AIR"));
        assertTrue(firstRow.get(3).getText().equals("ALLEGIANT AIR LLC"));
    }
    
    @Test
    public void testColumnRecognition() throws IOException {
        // TODO add assertions
        Page page = UtilsForTesting
                .getAreaFromFirstPage(
                        "src/test/resources/org/nerdpower/tabula/argentina_diputados_voting_record.pdf",
                        269.875f, 12.75f, 790.5f, 561f);
        BasicExtractionAlgorithm bea = new BasicExtractionAlgorithm();
        Table table = bea.extract(page).get(0);
        (new CSVWriter()).write(System.out, table);
    }
    
    @Test
    public void testVerticalRulingsPreventMergingOfColumns() throws IOException {
        List<Ruling> rulings = new ArrayList<Ruling>();
        Float[] rulingsVerticalPositions = { 147f, 256f, 310f, 375f, 431f, 504f };
        for (int i = 0; i < 6; i++) {
            rulings.add(new Ruling(0, rulingsVerticalPositions[i], 0, 1000));
        }

        Page page = UtilsForTesting.getAreaFromFirstPage(
                "src/test/resources/org/nerdpower/tabula/campaign_donors.pdf",
                255.57f, 40.43f, 398.76f, 557.35f);
        BasicExtractionAlgorithm bea = new BasicExtractionAlgorithm(rulings);
        Table table = bea.extract(page).get(0);
        List<RectangularTextContainer> sixthRow = table.getRows().get(5);

        assertTrue(sixthRow.get(0).getText().equals("VALSANGIACOMO BLANC"));
        assertTrue(sixthRow.get(1).getText().equals("OFERNANDO JORGE "));
    }
    
    @Test
    public void testDontRaiseSortException() throws IOException {
        Page page = UtilsForTesting.getAreaFromPage(
                "src/test/resources/org/nerdpower/tabula/us-017.pdf",
                2,
                446.0f, 97.0f, 685.0f, 520.0f);
        page.getText();
        //BasicExtractionAlgorithm bea = new BasicExtractionAlgorithm();
        SpreadsheetExtractionAlgorithm bea = new SpreadsheetExtractionAlgorithm();
        Table table = bea.extract(page).get(0);
        (new CSVWriter()).write(System.out, table);
    }
    
    @Test
    public void testNaturalOrderOfRectangles() throws IOException {
        Page page = UtilsForTesting.getPage("src/test/resources/org/nerdpower/tabula/us-017.pdf", 2).getArea(446.0f,97.0f,685.0f,520.0f);
        BasicExtractionAlgorithm bea = new BasicExtractionAlgorithm(page.getVerticalRulings());
        Table table = bea.extract(page).get(0);
        (new CSVWriter()).write(System.out, table);

        // List<TextChunk> chunks = TextElement.mergeWords(page.getText(), page.getVerticalRulings());
        
//        List<Rectangle> toSort = Arrays.asList(RECTANGLES_TEST_NATURAL_ORDER);
//        Collections.sort(toSort);
//        Rectangle x, y;
//        List<Rectangle[]> greaterThan = new ArrayList<Rectangle[]>();
//        for (int i = 0; i < RECTANGLES_TEST_NATURAL_ORDER.length - 2; i++) {
//            x = RECTANGLES_TEST_NATURAL_ORDER[i];
//            for (int j = i + 1; j < RECTANGLES_TEST_NATURAL_ORDER.length -1; j++) {
//                y = RECTANGLES_TEST_NATURAL_ORDER[j];
//                if (x.compareTo(y) > 0) {
//                    greaterThan.add(new Rectangle[] { x, y });
//                }
//            }
//        }
//
//        for (Rectangle[] gt: greaterThan) {
//            x = gt[0]; y = gt[1];
//            
//            for (Rectangle z: RECTANGLES_TEST_NATURAL_ORDER) {
//                if (y.compareTo(z) > 0 && !(x.compareTo(z) > 0)) {
//                    //System.out.println(x); System.out.println(y); System.out.println(z); System.out.println();
//                    System.out.println(x.verticalOverlap(y));
//                }
//            }
//        }
        
    }

}
