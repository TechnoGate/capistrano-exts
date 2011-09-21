class String
  # Returns a string without many empty lines
  def strip_empty_lines
    dup.strip_empty_lines!
  end

  def strip_empty_lines!
    strip!
    gsub!(/[\n]{3,}/, "\n\n")
    self
  end

  def strip_trailing_whitespace
    dup.strip_trailing_whitespace!
  end

  def strip_trailing_whitespace!
    strip!
    gsub!(/[ \t]+$/, '')
    self
  end
end
