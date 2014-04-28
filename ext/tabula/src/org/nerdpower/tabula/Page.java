package org.nerdpower.tabula;

import java.awt.geom.Rectangle2D;
import java.util.ArrayList;

@SuppressWarnings("serial")
public class Page extends Rectangle2D.Float {

	private Integer rotation;
	private int page_number;
	private ArrayList<TextElement> characters;
	private ArrayList<Ruling> rulings;
	private float minCharWidth;
	private float minCharHeight;

	public Page(float width, float height, Integer rotation, int page_number,
			ArrayList<TextElement> characters, ArrayList<Ruling> rulings,
			float minCharWidth, float minCharHeight) {
		
		super();
		this.setRect(0, 0, width, height);
		this.rotation = rotation;
		this.page_number = page_number;
		this.characters = characters;
		this.rulings = rulings;
		this.minCharHeight = minCharHeight;
		this.minCharWidth = minCharWidth;
	}

	public Integer getRotation() {
		return rotation;
	}

	public int getPage_number() {
		return page_number;
	}

	public ArrayList<TextElement> getCharacters() {
		return characters;
	}

	public ArrayList<Ruling> getRulings() {
		return rulings;
	}

	public float getMinCharWidth() {
		return minCharWidth;
	}

	public float getMinCharHeight() {
		return minCharHeight;
	}
}
