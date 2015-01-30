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
        tree <<  [ first, rest.size == 0 ? [nil] : add_to_tree(rest) ]
      else
        add_to_subtree(first,rest,prefix[0])
      end
      tree
    end

    def self.add_to_subtree(first,rest,tree)
      if has_children? tree
        add_to_children(first,rest,tree[1])
      else
        tree << add_to_tree(rest, [first]) unless rest.size == 0
      end
    end

    def self.has_children?(tree)
      case tree.length
      when 1 then false
      when 2 then true
      else        raise MalformedTreeError
      end
    end

    def self.add_to_children(first,rest,tree)
      if rest.size == 0
        # don't double-add nil if we already have this word
        tree << nil unless tree.one? { |e| e.nil? }
      else rest.size > 0
        add_to_tree(rest,tree)
      end
    end

    def self.abbrevs_of(tree)
      raise NotImplementedError
    end

  end #Builder
end #Abbrev
