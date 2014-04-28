package org.nerdpower.tabula;

import java.awt.geom.Line2D;

@SuppressWarnings("serial")
public class Ruling extends Line2D.Float {

	public Ruling(float top, float left, float width, float height) {
		super(left, top, left+width, top+height);
	}
	
	

}
