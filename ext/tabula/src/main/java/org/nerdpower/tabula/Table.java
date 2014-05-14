package org.nerdpower.tabula;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class Table {
    
    public static final Table EMPTY = new Table(0,0);
    
    Page page;
    ExtractionAlgorithm extractionAlgorithm;
    List<List<TextChunk>> cells;
    
    public Table(int rows, int columns) {
        this.cells = new ArrayList<List<TextChunk>>(rows);
        for (int i = 0; i < rows; i++) {
            List<TextChunk> row = new ArrayList<TextChunk>(columns);
            for (int j = 0; j < columns; j++) {
                row.add(TextChunk.EMPTY);
            }
            this.cells.add(row);
        }
    }
    
    public Table(int rows, int columns, Page page, ExtractionAlgorithm extractionAlgorithm) {
        this(rows, columns);
        this.page = page;
        this.extractionAlgorithm = extractionAlgorithm;
    }

    public void add(TextChunk tc, int i, int j) {
        this.cells.get(i).set(j, tc);
    }
    
    public List<List<TextChunk>> getRows() {
        Collections.sort(this.cells, new Comparator<List<TextChunk>>() {
            @Override
            public int compare(List<TextChunk> o1, List<TextChunk> o2) {
                return Double.compare(Rectangle.boundingBoxOf(o1).getBottom(), Rectangle.boundingBoxOf(o2).getBottom());
            }});
        return this.cells;
    }
    
    public List<List<TextChunk>> getCols() {
        return transpose(this.getRows());
    }
    
    private static <T> List<List<T>> transpose(List<List<T>> table) {
        List<List<T>> ret = new ArrayList<List<T>>();
        final int N = table.get(0).size();
        for (int i = 0; i < N; i++) {
            List<T> col = new ArrayList<T>();
            for (List<T> row : table) {
                col.add(row.get(i));
            }
            ret.add(col);
        }
        return ret;
    }
}
