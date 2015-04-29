require 'minitest/spec'
require 'minitest/autorun'
require_relative 'abbrev_builder'

## alias the class so we don't have to wear our fingers down.
describe Abbrev::Builder do
  before :each do
    @class = Abbrev::Builder
    @builder = @class.new
  end

  it "responds to :new with an instance" do
    @builder.instance_of?(@class).must_equal true
  end

  it "builds a hash of abbreviations, like abbrev" do
    @builder.build.must_respond_to :[]
  end

  # I don't yet know how to assert that code does not throw errors,
  # other than to not do any asserts
  it "accepts new words" do
    @builder.add_word('new')
  end

  it "accepts new words (chainable)" do
    @builder.add_word('new').must_be_kind_of @class
  end

  it "should be chainable" do
    @builder.add_word('cat').add_word('car').kind_of?(@class)
      .must_equal true
  end

  it "generates abbreviations for words it contains" do
    @builder.add_word('new').build['n'].must_equal 'new'
    @builder.build.values.must_include 'new'
  end

  it "generates distinct abbreviations" do
    abbrevs = @builder
      .add_word('cat')
      .add_word('car')
      .add_word('cattle')
      .build
    abbrevs['catt'].must_equal "cattle"
    abbrevs['cat'].must_equal "cat"
    abbrevs['car'].must_equal "car"
  end

  describe "Array-based trees" do
    # This part of the spec will have to change if I change my tree
    # representation. Is including this in my spec a mistake? Or will it
    # focus my refactoring better?
    it "are generated from strings" do
      @class.add_to_tree("a").must_equal [['a',[nil]]]
    end

    it "can incorporate new strings that share a prefix" do
      a = @class.add_to_tree("a")
      @class.add_to_tree("aa",a).must_equal [['a', [nil, ['a', [nil]] ] ]]
      @class.add_to_tree("ab",a)
        .must_equal [['a', [nil, ['a', [nil]], ['b',[nil]]] ]]
    end

    it "don't need to be started with single-character words" do
      states = @class.add_to_tree("CA")
      states.must_equal [['C', [['A',[nil]]] ]]
      @class.add_to_tree("CT",states)
      states.must_equal [[ 'C', [['A',[nil]],['T',[nil]]] ]]

      catcar = @class.add_to_tree("cat")
      catcar.must_equal [['c', [['a', [['t',[nil]]] ]] ]]
      @class.add_to_tree("car",catcar)
        .must_equal [['c', [['a', [['t',[nil]], ['r',[nil]]] ]] ]]
    end

    it "can extend themselves longer words" do
      expected = [['c', [['a', [['t', [nil,['s',[nil] ]] ]] ]] ]]

      a = @class.add_to_tree("cat")
      @class.add_to_tree("cats",a).must_equal expected
    end

    it "don't change if you add the same word twice" do
      expected = [['c', [['a', [['r', [nil, ['t',[nil]]] ]] ]] ]]

      a = @class.add_to_tree("car")
      @class.add_to_tree("cart",a)
      @class.add_to_tree("cart",a).must_equal expected
    end

    it "incorporate sub-words" do
      # have to show that both "car" and "cart are in the tree (for
      # later traversal).
      initial  = [[ 'c', [['a', [['r', [['t',[nil]]] ]] ]] ]]
      expected = [[ 'c', [['a', [['r', [['t',[nil]],nil] ]] ]] ]]
      a = @class.add_to_tree("cart")
      a.must_equal initial
      @class.add_to_tree("car",a).must_equal expected
    end

    describe "instances" do
      before :each do
        @leaf = ['a',[nil]]
        @branch = ['a',[['b',[nil]],['a',[nil]]]]
      end

      it "know their :value and :children" do
        @leaf.must_respond_to :value
        @leaf.must_respond_to :children
        @branch.must_respond_to :value
        @branch.must_respond_to(:children)

        @leaf.value.must_equal 'a'
        @branch.value.must_equal 'a'

        @leaf.has_children?.must_equal true
        @branch.has_children?.must_equal true

        @leaf.children.must_equal [nil]
        @branch.children.must_equal [['b',[nil]],['a',[nil]]]
      end

      it "know if they are a stem, leaf, branch, or word ending" do
        @leaf.is_leaf?.must_equal true
        @leaf.word_ending?.must_equal true
        @branch.children.each { |child| child.word_ending?.must_equal true }
      end
    end
  end

  describe "abbreviations" do
    a = [['a',[nil]]]
    # tree containing "a", "aa" and "ab". Should generate:
    # { "a"  => "a",
    #   "aa" => "aa",
    #   "ab" => "ab", }
    a_aa_ab = [['a', [nil,['a',[nil]],['b',[nil]]] ]]
    carcat = [['c', [['a', [['r',[nil]],['t',[nil]]] ]] ]]
    carcart = [['c', [['a', [['r',[nil,['t',[nil]]]]] ]] ]]

    it "are extracted from trees" do
      @class.abbrevs_of(a)['a'].must_equal 'a'
    end

    it "are built from trees" do
      @class.abbrevs_of(carcat)['car'].must_equal 'car'
      @class.abbrevs_of(carcat)['cat'].must_equal 'cat'
      @class.abbrevs_of(carcart)['car'].must_equal 'car'
      @class.abbrevs_of(carcart)['cart'].must_equal 'cart'
    end

    it "are generated as a whole" do
      abbrevs = @class.abbrevs_of(a_aa_ab)
      abbrevs['a'].must_equal 'a'
      abbrevs['aa'].must_equal('aa')
      abbrevs['ab'].must_equal('ab')
    end
  end
end
