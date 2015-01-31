require 'abbrev'

# Exapt tree stuff from Abbrev::Builder for prettiness
class Array

  def value
    return self[0] unless self[0].kind_of? Array
  end

  def children
    return self[1] if self[1].kind_of? Array
    return []
  end

  def has_children? 
    case length
    when 1 then false
    when 2 then true
    else        raise "Not a tree: #{self.inspect}"
    end
  end

  # a tree is a branch if it has children 
  def is_branch?
    return false unless has_children?
    return children.length > 1
  end

  def is_stem?
    return false unless has_children?
    return false if is_leaf?
    return children.length <= 1
  end

  def is_leaf?
    children == [nil]
  end

  def word_ending?
    has_children? && children.one? { |e| e.nil? }
  end

end

module Abbrev
  class Builder
    # I'm purposefully doing this badly, keeping an array of words and
    # building a tree each time I generate abbreviations. I'm doing
    # teaching myself RSpec, so I wanna have refactoring work to do
    # while maintaining compliance with the spec.
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
      if tree.has_children?
        add_to_children(first,rest,tree[1])
      else
        tree << add_to_tree(rest, [first]) unless rest.size == 0
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
      abbrevs = {}
      tree.each { |subtree| tree_inject(abbrevs,'','',subtree) }
      abbrevs
    end

    # This is ugly enough to beg refactoring. Maybe Trees need to be
    # their own class, with something like this accomplished through
    # their own :inject method?
    def self.tree_inject(hash,prefix,full,tree)
      return if tree.nil?
      # thankfully + doesn't modify strings in place
      a = prefix
      b = full + tree.value
      if tree.is_stem?
        a = a_or_b hash, a, b
        tree.children.each { |t| tree_inject(hash,a,b,t) } if tree.has_children?
      elsif tree.is_branch?
        # add the current full word if this is the end 
        hash[b] = b if tree.word_ending?
        # also add any children that are word-endings 
        endings = tree.children.select { |child| child && child.word_ending? }
        endings.each do |child|
          final = b + child.value
          hash[final] = final
        end
        # recurse through the remaining children
        tree.children.each { |t| tree_inject(hash,b,b,t) }
      elsif tree.is_leaf?
        a = a_or_b(hash,a,b)
        hash[a] = b unless hash.rassoc(b)
      else
        warn "CAN'T HAPPEN!"
      end
    end

    def self.a_or_b(hash,a,b)
      (a.size == 0 || !hash.assoc(a).nil?) ? b : a
    end
    
  end #Builder
end #Abbrev
