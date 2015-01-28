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
      @words.each { |word| add_to_subtree(word,@tree) }
    end

    def traverse_tree
      raise NotImplementedError
    end

    def self.add_to_subtree(word,tree)
      prefix = tree.select { |e| e[0] == word[0] }
      if prefix.empty?
        tree << [ word[0], [word[1..word.size]] ]
      else
        add_to_subtree word[1..word.size], prefix[1]
      end
    end
  end #Builder
end #Abbrev
