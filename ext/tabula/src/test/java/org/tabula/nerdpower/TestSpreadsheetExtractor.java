package org.tabula.nerdpower;

import static org.junit.Assert.*;

import java.util.Arrays;
import java.util.List;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.nerdpower.tabula.Cell;
import org.nerdpower.tabula.Rectangle;
import org.nerdpower.tabula.extractors.SpreadsheetExtractionAlgorithm;

public class TestSpreadsheetExtractor {

    private static final Cell[] CELLS = new Cell[] {
            new Cell(40.0f, 18.0f, 208.0f, 4.0f),
            new Cell(44.0f, 18.0f, 52.0f, 6.0f),
            new Cell(50.0f, 18.0f, 52.0f, 4.0f),
            new Cell(54.0f, 18.0f, 52.0f, 6.0f),
            new Cell(60.0f, 18.0f, 52.0f, 4.0f),
            new Cell(64.0f, 18.0f, 52.0f, 6.0f),
            new Cell(70.0f, 18.0f, 52.0f, 4.0f),
            new Cell(74.0f, 18.0f, 52.0f, 6.0f),
            new Cell(90.0f, 18.0f, 52.0f, 4.0f),
            new Cell(94.0f, 18.0f, 52.0f, 6.0f),
            new Cell(100.0f, 18.0f, 52.0f, 28.0f),
            new Cell(128.0f, 18.0f, 52.0f, 4.0f),
            new Cell(132.0f, 18.0f, 52.0f, 64.0f),
            new Cell(196.0f, 18.0f, 52.0f, 66.0f),
            new Cell(262.0f, 18.0f, 52.0f, 4.0f),
            new Cell(266.0f, 18.0f, 52.0f, 84.0f),
            new Cell(350.0f, 18.0f, 52.0f, 4.0f),
            new Cell(354.0f, 18.0f, 52.0f, 32.0f),
            new Cell(386.0f, 18.0f, 52.0f, 38.0f),
            new Cell(424.0f, 18.0f, 52.0f, 18.0f),
            new Cell(442.0f, 18.0f, 52.0f, 74.0f),
            new Cell(516.0f, 18.0f, 52.0f, 28.0f),
            new Cell(544.0f, 18.0f, 52.0f, 4.0f),
            new Cell(44.0f, 70.0f, 156.0f, 6.0f),
            new Cell(50.0f, 70.0f, 156.0f, 4.0f),
            new Cell(54.0f, 70.0f, 156.0f, 6.0f),
            new Cell(60.0f, 70.0f, 156.0f, 4.0f),
            new Cell(64.0f, 70.0f, 156.0f, 6.0f),
            new Cell(70.0f, 70.0f, 156.0f, 4.0f),
            new Cell(74.0f, 70.0f, 156.0f, 6.0f),
            new Cell(84.0f, 70.0f, 2.0f, 6.0f),
            new Cell(90.0f, 70.0f, 156.0f, 4.0f),
            new Cell(94.0f, 70.0f, 156.0f, 6.0f),
            new Cell(100.0f, 70.0f, 156.0f, 28.0f),
            new Cell(128.0f, 70.0f, 156.0f, 4.0f),
            new Cell(132.0f, 70.0f, 156.0f, 64.0f),
            new Cell(196.0f, 70.0f, 156.0f, 66.0f),
            new Cell(262.0f, 70.0f, 156.0f, 4.0f),
            new Cell(266.0f, 70.0f, 156.0f, 84.0f),
            new Cell(350.0f, 70.0f, 156.0f, 4.0f),
            new Cell(354.0f, 70.0f, 156.0f, 32.0f),
            new Cell(386.0f, 70.0f, 156.0f, 38.0f),
            new Cell(424.0f, 70.0f, 156.0f, 18.0f),
            new Cell(442.0f, 70.0f, 156.0f, 74.0f),
            new Cell(516.0f, 70.0f, 156.0f, 28.0f),
            new Cell(544.0f, 70.0f, 156.0f, 4.0f),
            new Cell(84.0f, 72.0f, 446.0f, 6.0f),
            new Cell(90.0f, 226.0f, 176.0f, 4.0f),
            new Cell(94.0f, 226.0f, 176.0f, 6.0f),
            new Cell(100.0f, 226.0f, 176.0f, 28.0f),
            new Cell(128.0f, 226.0f, 176.0f, 4.0f),
            new Cell(132.0f, 226.0f, 176.0f, 64.0f),
            new Cell(196.0f, 226.0f, 176.0f, 66.0f),
            new Cell(262.0f, 226.0f, 176.0f, 4.0f),
            new Cell(266.0f, 226.0f, 176.0f, 84.0f),
            new Cell(350.0f, 226.0f, 176.0f, 4.0f),
            new Cell(354.0f, 226.0f, 176.0f, 32.0f),
            new Cell(386.0f, 226.0f, 176.0f, 38.0f),
            new Cell(424.0f, 226.0f, 176.0f, 18.0f),
            new Cell(442.0f, 226.0f, 176.0f, 74.0f),
            new Cell(516.0f, 226.0f, 176.0f, 28.0f),
            new Cell(544.0f, 226.0f, 176.0f, 4.0f),
            new Cell(90.0f, 402.0f, 116.0f, 4.0f),
            new Cell(94.0f, 402.0f, 116.0f, 6.0f),
            new Cell(100.0f, 402.0f, 116.0f, 28.0f),
            new Cell(128.0f, 402.0f, 116.0f, 4.0f),
            new Cell(132.0f, 402.0f, 116.0f, 64.0f),
            new Cell(196.0f, 402.0f, 116.0f, 66.0f),
            new Cell(262.0f, 402.0f, 116.0f, 4.0f),
            new Cell(266.0f, 402.0f, 116.0f, 84.0f),
            new Cell(350.0f, 402.0f, 116.0f, 4.0f),
            new Cell(354.0f, 402.0f, 116.0f, 32.0f),
            new Cell(386.0f, 402.0f, 116.0f, 38.0f),
            new Cell(424.0f, 402.0f, 116.0f, 18.0f),
            new Cell(442.0f, 402.0f, 116.0f, 74.0f),
            new Cell(516.0f, 402.0f, 116.0f, 28.0f),
            new Cell(544.0f, 402.0f, 116.0f, 4.0f),
            new Cell(84.0f, 518.0f, 246.0f, 6.0f),
            new Cell(90.0f, 518.0f, 186.0f, 4.0f),
            new Cell(94.0f, 518.0f, 186.0f, 6.0f),
            new Cell(100.0f, 518.0f, 186.0f, 28.0f),
            new Cell(128.0f, 518.0f, 186.0f, 4.0f),
            new Cell(132.0f, 518.0f, 186.0f, 64.0f),
            new Cell(196.0f, 518.0f, 186.0f, 66.0f),
            new Cell(262.0f, 518.0f, 186.0f, 4.0f),
            new Cell(266.0f, 518.0f, 186.0f, 84.0f),
            new Cell(350.0f, 518.0f, 186.0f, 4.0f),
            new Cell(354.0f, 518.0f, 186.0f, 32.0f),
            new Cell(386.0f, 518.0f, 186.0f, 38.0f),
            new Cell(424.0f, 518.0f, 186.0f, 18.0f),
            new Cell(442.0f, 518.0f, 186.0f, 74.0f),
            new Cell(516.0f, 518.0f, 186.0f, 28.0f),
            new Cell(544.0f, 518.0f, 186.0f, 4.0f),
            new Cell(90.0f, 704.0f, 60.0f, 4.0f),
            new Cell(94.0f, 704.0f, 60.0f, 6.0f),
            new Cell(100.0f, 704.0f, 60.0f, 28.0f),
            new Cell(128.0f, 704.0f, 60.0f, 4.0f),
            new Cell(132.0f, 704.0f, 60.0f, 64.0f),
            new Cell(196.0f, 704.0f, 60.0f, 66.0f),
            new Cell(262.0f, 704.0f, 60.0f, 4.0f),
            new Cell(266.0f, 704.0f, 60.0f, 84.0f),
            new Cell(350.0f, 704.0f, 60.0f, 4.0f),
            new Cell(354.0f, 704.0f, 60.0f, 32.0f),
            new Cell(386.0f, 704.0f, 60.0f, 38.0f),
            new Cell(424.0f, 704.0f, 60.0f, 18.0f),
            new Cell(442.0f, 704.0f, 60.0f, 74.0f),
            new Cell(516.0f, 704.0f, 60.0f, 28.0f),
            new Cell(544.0f, 704.0f, 60.0f, 4.0f),
            new Cell(84.0f, 764.0f, 216.0f, 6.0f),
            new Cell(90.0f, 764.0f, 216.0f, 4.0f),
            new Cell(94.0f, 764.0f, 216.0f, 6.0f),
            new Cell(100.0f, 764.0f, 216.0f, 28.0f),
            new Cell(128.0f, 764.0f, 216.0f, 4.0f),
            new Cell(132.0f, 764.0f, 216.0f, 64.0f),
            new Cell(196.0f, 764.0f, 216.0f, 66.0f),
            new Cell(262.0f, 764.0f, 216.0f, 4.0f),
            new Cell(266.0f, 764.0f, 216.0f, 84.0f),
            new Cell(350.0f, 764.0f, 216.0f, 4.0f),
            new Cell(354.0f, 764.0f, 216.0f, 32.0f),
            new Cell(386.0f, 764.0f, 216.0f, 38.0f),
            new Cell(424.0f, 764.0f, 216.0f, 18.0f),
            new Cell(442.0f, 764.0f, 216.0f, 74.0f),
            new Cell(516.0f, 764.0f, 216.0f, 28.0f),
            new Cell(544.0f, 764.0f, 216.0f, 4.0f) };

    @Before
    public void setUp() throws Exception {
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void testFindSpreadsheetsFromCells() {
        SpreadsheetExtractionAlgorithm se = new SpreadsheetExtractionAlgorithm();
        List<? extends Rectangle> cells = Arrays.asList(CELLS);
        System.out.println(se.findSpreadsheetsFromCells(cells));
        System.out.println("mierda");

    }

}
