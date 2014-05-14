package org.nerdpower.tabula;

import java.util.List;

public interface ExtractionAlgorithm {

    List<Table> extract(Page page);
    String toString();
    
}
