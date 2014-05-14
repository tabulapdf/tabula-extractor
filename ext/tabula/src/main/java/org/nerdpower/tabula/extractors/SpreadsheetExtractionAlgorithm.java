package org.nerdpower.tabula.extractors;

import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

import org.nerdpower.tabula.Cell;
import org.nerdpower.tabula.Page;
import org.nerdpower.tabula.Ruling;
import org.nerdpower.tabula.Table;

public class SpreadsheetExtractionAlgorithm implements ExtractionAlgorithm {
    
    private static final Comparator<Point2D> POINT_COMPARATOR = new Comparator<Point2D>() {
        @Override
        public int compare(Point2D arg0, Point2D arg1) {
            int rv = 0;
            if (arg0.getY() > arg1.getY()) {
                rv = 1;
            }
            else if (arg0.getY() < arg1.getY()) {
                rv = -1;
            }
            else if (arg0.getX() > arg1.getX()) {
                rv = 1;
            }
            else if (arg0.getX() < arg1.getX()) {
                rv = -1;
            }
            return rv;
        }
    };

    @Override
    public List<Table> extract(Page page) {
        // TODO Auto-generated method stub
        return null;
    }
    
    public List<Cell> findCells(List<Ruling> horizontalRulingLines, List<Ruling> verticalRulingLines) {
        List<Cell> cellsFound = new ArrayList<Cell>();
        Map<Point2D, Ruling[]> intersectionPoints = Ruling.findIntersections(horizontalRulingLines, verticalRulingLines);
        List<Point2D> intersectionPointsList = new ArrayList<Point2D>(intersectionPoints.keySet());
        boolean doBreak = false;
        
        Collections.sort(intersectionPointsList, POINT_COMPARATOR); 
        
        
        for (int i = 0; i < intersectionPointsList.size(); i++) {
            Point2D topLeft = intersectionPointsList.get(i);
            Ruling[] hv = intersectionPoints.get(topLeft);
            doBreak = false;
            
            // CrossingPointsDirectlyBelow( topLeft );
            // CrossingPointsDirectlyToTheRight( topLeft );

            List<Point2D> xPoints = new ArrayList<Point2D>();
            List<Point2D> yPoints = new ArrayList<Point2D>();

                
            for (Point2D p: intersectionPointsList.subList(i, intersectionPointsList.size())) {
//                System.out.println("here");
                if (p.getX() == topLeft.getX() && p.getY() > topLeft.getY()) {
                    xPoints.add(p);
                }
                if (p.getY() == topLeft.getY() && p.getX() > topLeft.getX()) {
                    yPoints.add(p);
                }
            }
            outer:
            for (Point2D xPoint: xPoints) {
                if (doBreak) { break; }

                if (!hv[1].colinear(xPoint)) {
                    continue;
                }
                for (Point2D yPoint: yPoints) {
                    if (!hv[0].colinear(yPoint)) {
                        continue;
                    }
                    Point2D btmRight = new Point2D.Float((float) yPoint.getX(), (float) xPoint.getY());
                    if (intersectionPoints.containsKey(btmRight)) {
                        Ruling[] btmRightHV = intersectionPoints.get(btmRight);
                        if (btmRightHV[0].colinear(xPoint) && btmRightHV[1].colinear(yPoint)) {
                            cellsFound.add(new Cell(topLeft, btmRight));
                        }
//                        System.out.println("breaking");
                        doBreak = true;
                        break outer;
                    }
                }
            }
            // if (doBreak) { continue; }
        }
        return cellsFound;
        
        
    }
    
    public String toString() {
        return "spreadsheet";
    }

}
