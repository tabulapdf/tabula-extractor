package org.nerdpower.tabula.extractors;

import java.util.List;

import org.nerdpower.tabula.Page;
import org.nerdpower.tabula.Table;

public interface ExtractionAlgorithm {

    List<Table> extract(Page page);
    String toString();
    
}
