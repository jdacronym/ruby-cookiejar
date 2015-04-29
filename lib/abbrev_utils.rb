require 'abbrev'

# Augment Abbrev, Hash and Array with some handy functions, and abuse the
# living heck out of inject.

class Hash
  # Get all keys associated with a value. That is, reverse a(ll)assoc. 
  def raassoc(value)
    [value,  self.inject([]) { |acc,(k,v)| acc << k if v == value }]
  end

  # non-catastropically invert a hash by bucketing equivalent keys. I'm
  # surprised I didn't find this in Hash to begin with.
  def invert_assoc
    self.inject({}) do |acc,(k,v)|
      acc[v] ||= self.raassoc(v)[1]
      acc
    end
  end
end

module Abbrev
  module_function
  # Since ruby hashses are ordered since 1.9, and abbrev works in decreasing
  # length, we can just invert the result of abbrev twice and get only the
  # shortest keys.
  def shortest_abbrev(words, pattern = nil)
    Abbrev::abbrev(words,pattern).invert.invert
  end

  # get a mapping from a set of words to their abbrevations
  def abbrev_assoc(words, pattern = nil)
    Abbrev::abbrev(words,pattern).invert_assoc
  end

  # Clamp abbrevations to a size. Not quite the opposite of shortest_abbrev: a
  # word is sorta by definition its own longest abbreviation. :\
  def field_abbrev(words, width = nil, pattern = nil)
    Abbrev::abbrev_assoc(words,pattern).inject({}) do |results, pair|
      k,v = pair
      selection = case width
                  when Numeric then v.select{ |e| e.size <= width }
                  else              v
                  end
      results[k] = selection.sort_by{ |e| e.size }.last
      results
    end
  end

  ## but we want more. We only want words abbreviated if they need to be. Why
  ## use "cal" as an abbreviation for "call" If there are no other words
  ## matching /^cal/. To be continued...
  def minimal_abbrev(words, width = nil, pattern = nil)
    raise "Not Implemented"
  end
end #Abbrev

class Array
  def shortest_abbrev(pattern = nil)
    Abbrev::shortest_abbrev(self,pattern)
  end

  def abbrev_assoc(pattern = nil)
    Abbrev::abbrev_assoc(self,pattern)
  end
end
