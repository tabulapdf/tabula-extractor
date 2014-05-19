package org.nerdpower.tabula.writers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.CSVFormat;
import org.nerdpower.tabula.Table;
import org.nerdpower.tabula.TextChunk;

public class CSVWriter {
    
    public static void writeTable(Appendable out, Table table) throws IOException {
        CSVPrinter printer = new CSVPrinter(out, CSVFormat.EXCEL);
        for (List<TextChunk> row: table.getRows()) {
            List<String> cells = new ArrayList<String>(row.size());
            for (TextChunk tc: row) {
                cells.add(tc.getText());
            }
            printer.printRecord(cells);
        }
        printer.close();
    }
}
