package org.nerdpower.tabula;

import gnu.trove.procedure.TIntProcedure;

import java.awt.geom.Rectangle2D;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.infomatiq.jsi.Rectangle;
import com.infomatiq.jsi.SpatialIndex;
import com.infomatiq.jsi.rtree.RTree;

@SuppressWarnings("serial")
public class TextElementIndex {
    
    class SaveToListProcedure implements TIntProcedure {
        private List<Integer> ids = new ArrayList<Integer>();

        public boolean execute(int id) {
          ids.add(id);
          return true;
        };
        
        private List<Integer> getIds() {
          return ids;
        }
    };
	
    private SpatialIndex si;
    private List<TextElement> textElements;
    
    public TextElementIndex() {
        si = new RTree();
        si.init(null);
        textElements = new ArrayList<TextElement>();
    }
    
    public void add(TextElement te) {
        textElements.add(te);
        si.add(rectangle2DToSpatialIndexRectangle(te), textElements.size() - 1);
    }
    
    public Iterable<TextElement> contains(Rectangle2D r) {
        SaveToListProcedure proc = new SaveToListProcedure();
        si.contains(rectangle2DToSpatialIndexRectangle(r), proc);
        ArrayList<TextElement> rv = new ArrayList<TextElement>();
        for (int i : proc.getIds()) {
            rv.add(textElements.get(i));
        }
        Collections.sort(rv);
        return rv;
    }
    
    private static Rectangle rectangle2DToSpatialIndexRectangle(Rectangle2D r) {
        return new Rectangle((float) r.getMinX(),
                (float) r.getMinY(),
                (float) r.getMaxX(),
                (float) r.getMaxY());
    }

}
