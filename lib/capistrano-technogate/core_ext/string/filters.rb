class String
  # Returns the string, first removing all whitespace on both ends of
  # the string, and then changing remaining consecutive whitespace
  # groups into one space each.
  #
  # Examples:
  #   %{ Multi-line
  #      string }.squish                   # => "Multi-line string"
  #   " foo   bar    \n   \t   boo".squish # => "foo bar boo"
  def squish
    dup.squish!
  end

  # Performs a destructive squish. See String#squish.
  def squish!
    strip!
    gsub!(/\s+/, ' ')
    self
  end

  # Returns a string without many empty lines
  def compact
    dup.compact!
  end

  def compact!
    strip!
    gsub!(/[\n]{3,}/, "\n\n")
    self
  end
end
