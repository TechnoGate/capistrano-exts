class String
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
