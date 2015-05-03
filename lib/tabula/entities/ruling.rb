class Tabula::Ruling < Java::TechnologyTabula::Ruling

  # some PDFs (garment factory audits, precise link TK) make tables by drawing lines that
  # very nearly intersect each other, but not quite. E.g. a horizontal line spans the table at a Y val of 100
  # and each vertical line (i.e. column separating ruling line) starts at 101 or 102.
  # this is very annoying. so we check if those lines nearly overlap by expanding each pair
  # by 2 pixels in each direction (so the vertical lines' top becomes 99 or 100, and then the expanded versions overlap)

  def to_json(arg)
    [left, top, right, bottom].to_json
  end
end
