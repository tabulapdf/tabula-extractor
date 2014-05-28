package org.nerdpower.tabula.debug;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.Shape;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Point2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.nerdpower.tabula.CommandLineApp;
import org.nerdpower.tabula.ObjectExtractor;
import org.nerdpower.tabula.Page;
import org.nerdpower.tabula.Rectangle;
import org.nerdpower.tabula.Ruling;
import org.nerdpower.tabula.Table;
import org.nerdpower.tabula.TextChunk;
import org.nerdpower.tabula.TextElement;
import org.nerdpower.tabula.Utils;
import org.nerdpower.tabula.extractors.SpreadsheetExtractionAlgorithm;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.pdfbox.util.ImageIOUtil;

public class Debug {
    
    private static final float CIRCLE_RADIUS = 5f;
        
    private static final Color[] COLORS = { new Color(27, 158, 119),
            new Color(217, 95, 2), new Color(117, 112, 179),
            new Color(231, 41, 138), new Color(102, 166, 30) };

    public static void debugIntersections(Graphics2D g, Page page) {
        int i = 0;
        for (Point2D p: Ruling.findIntersections(page.getHorizontalRulings(), page.getVerticalRulings()).keySet()) {
            g.setColor(COLORS[(i++) % 5]);
            g.fill(new Ellipse2D.Float((float) p.getX() - CIRCLE_RADIUS/2f, (float) p.getY() - CIRCLE_RADIUS/2f, 5f, 5f));
        }
    }
    
    private static void debugRulings(Graphics2D g, Page page) {
        // draw detected lines
        List<Ruling> rulings = new ArrayList<Ruling>(page.getHorizontalRulings());
        rulings.addAll(page.getVerticalRulings());
        drawShapes(g, rulings);
    }
    
    private static void debugTextChunks(Graphics2D g, Page page) {
        List<TextChunk> chunks = TextElement.mergeWords(page.getText(), page.getVerticalRulings());
        drawShapes(g, chunks);
    }
    
    private static void debugSpreadsheets(Graphics2D g, Page page) {
        SpreadsheetExtractionAlgorithm sea = new SpreadsheetExtractionAlgorithm();
        List<? extends Table> tables = sea.extract(page);
        drawShapes(g, tables);
    }
    
    private static void drawShapes(Graphics2D g, Collection<? extends Shape> shapes) {
        int i = 0;
        g.setStroke(new BasicStroke(2f));
        for (Shape s: shapes) {
            g.setColor(COLORS[(i++) % 5]);
            drawShape(g, s);
        }
    }
    
    private static void drawShape(Graphics2D g, Shape shape) {
        g.setStroke(new BasicStroke(2f));
        g.draw(shape);
    }

    public static void renderPage(String pdfPath, String outPath, int pageNumber, 
            boolean drawTextChunks, boolean drawSpreadsheets, boolean drawRulings, boolean drawIntersections) throws IOException {
        PDDocument document = PDDocument.load(pdfPath);
        PDFRenderer renderer = new PDFRenderer(document);
        BufferedImage image = renderer.renderImage(pageNumber);
        
        ObjectExtractor oe = new ObjectExtractor(document);
        Page page = oe.extract(pageNumber + 1);
        
        Graphics2D g = (Graphics2D) image.getGraphics();
        
        if (drawTextChunks) {
            debugTextChunks(g, page);
        }
        if (drawSpreadsheets) {
            debugSpreadsheets(g, page);
        }
        if (drawRulings) {
            debugRulings(g, page);
        }
        if (drawIntersections) {
            debugIntersections(g, page);
        }

        document.close();
        
        ImageIOUtil.writeImage(image, outPath, 72);
    }
    
    private static Options buildOptions() {
        Options o = new Options();
        
        o.addOption("h", "help", false, "Print this help text.");
        o.addOption("r", "rulings", false, "Show detected rulings.");
        o.addOption("i", "intersections", false, "Show intersections between rulings.");
        o.addOption("s", "spreadsheets", false, "Show detected spreadsheets.");
        o.addOption("t", "textchunks", false, "Show detected text chunks (merged characters)");
        o.addOption(OptionBuilder.withLongOpt("pages")
                .withDescription("Comma separated list of ranges, or all. Examples: --pages 1-3,5-7, --pages 3 or --pages all. Default is --pages 1")
                .hasArg()
                .withArgName("PAGES")
                .create("p"));
        return o;
    }
   
    
    public static void main(String[] args) {
        CommandLineParser parser = new GnuParser();
        try {
            // parse the command line arguments
            CommandLine line = parser.parse(buildOptions(), args );
            List<Integer> pages = new ArrayList<Integer>();
            if (line.hasOption('p')) {
                pages = CommandLineApp.parsePagesOption(line.getOptionValue('p'));
            }
            else {
                pages.add(1);
            }
            
            if (line.hasOption('h')) {
                printHelp();
                System.exit(0);
            }
            
            if (line.getArgs().length != 1) {
                throw new ParseException("Need one filename\nTry --help for help");
            }
            
            File pdfFile = new File(line.getArgs()[0]);
            if (!pdfFile.exists()) {
                throw new ParseException("File does not exist");
            }
            
            for (int i: pages) {
                renderPage(pdfFile.getAbsolutePath(),
                           new File(pdfFile.getParent(), removeExtension(pdfFile.getName()) + "-" + (i) + ".jpg").getAbsolutePath(),
                           i-1,
                           line.hasOption('t'),
                           line.hasOption('s'),
                           line.hasOption('r'), 
                           line.hasOption('i'));
            }
        }
        catch (ParseException e) {
            System.err.println("Error: " + e.getMessage());
            System.exit(1);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    

    private static void printHelp() {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("tabula-debug", "Generate debugging images", buildOptions(), "", true);
    }
    
    private static String removeExtension(String s) {

        String separator = System.getProperty("file.separator");
        String filename;

        // Remove the path upto the filename.
        int lastSeparatorIndex = s.lastIndexOf(separator);
        if (lastSeparatorIndex == -1) {
            filename = s;
        } else {
            filename = s.substring(lastSeparatorIndex + 1);
        }

        // Remove the extension.
        int extensionIndex = filename.lastIndexOf(".");
        if (extensionIndex == -1)
            return filename;

        return filename.substring(0, extensionIndex);
    }
    
    
    
    
}
