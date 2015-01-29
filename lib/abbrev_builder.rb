require 'abbrev'

module Abbrev
  class Builder
    ## I'm purposefully doing this badl, keeping an array of words and
    ## building a tree each time I generate abbreviations. I'm doing
    ## teaching myself RSpec, so I wanna have refactoring work to do
    ## while maintaining compliance with the spec.
    def initialize(words = []) 
      @words = words
    end

    def add_word(word)
      @words << word
      self
    end

    def build
      build_tree
      traverse_tree
    end

    def build_tree
      @tree = []
      @words.each { |word| Abbrev::Builder.add_to_tree(word,@tree) }
    end

    def traverse_tree
      Abbrev::Builder.abbrevs_of(@tree)
    end

    ##this will be futher refactored. Wish I had macros. :|
    def self.add_to_tree(word,tree = [])
      first  = word[0]
      rest   = word[1..word.size]
      prefix = tree.select { |subtree| subtree && subtree[0] == first }
      if prefix.empty?
        if rest.size == 0
          tree << [ first, [nil] ] 
        else
          tree << [ first, add_to_tree(rest) ]
        end
      else
        match = prefix[0]
        case match.length
        when 1 
          if rest.size == 0
            tree
          else
             match << add_to_tree(rest, [first])
          end
        when 2
          if rest.size == 0
            match[1] << nil unless match[1].one? { |e| e.nil? }
          else
            add_to_tree rest, match[1]
          end
        else        raise MalformedTreeError
        end
      end
      tree
    end

    def self.abbrevs_of(tree)
      raise NotImplementedError
    end

  end #Builder
end #Abbrev
