require 'rspec'
require 'abbrev_builder'

## alias the class so we don't have to wear our fingers down.
Builder = Abbrev::Builder
describe Builder do
  before :each do
    @builder = Builder.new
  end

  it "responds to :new with an instance" do
    expect(@builder.instance_of?(Builder)).to eq(true)
  end

  it "builds a hash of abbreviations, like abbrev" do
    expect(@builder.build).to respond_to(:[])
  end

  it "accepts new words" do
    @builder.add_word('new')
  end

  it "accepts new words (chainable)" do
    expect(@builder.add_word('new').kind_of?(Builder)).to eq(true)
  end

  it "should be chainable" do
    expect(@builder.add_word('cat').add_word('car').kind_of?(Builder))
      .to eq(true)
  end

  it "generates abbreviations for words it contains" do
    expect(@builder.add_word('new').build['n']).to eq('new')
    expect(@builder.build.values).to include('new')
  end

  it "generates distinct abbreviations" do
    abbrevs = @builder
      .add_word('cat')
      .add_word('car')
      .add_word('cattle')
      .build
    expect(abbrevs['catt']).to eq("cattle")
    expect(abbrevs['cat']).to  eq("cat")
    expect(abbrevs['car']).to  eq("car")
  end
end


describe "Array-based trees" do
  # This part of the spec will have to change if I change my tree
  # representation. Is including this in my spec a mistake? Or will it
  # focus my refactoring better?
  it "are generated from strings" do
    expect(Builder.add_to_tree("a")).to eq([['a',[nil]]])
  end

  it "can incorporate new strings that share a prefix" do
    a = Builder.add_to_tree("a")
    expect(Builder.add_to_tree("aa",a)).to eq([['a', [nil, ['a', [nil]] ] ]])
    expect(Builder.add_to_tree("ab",a))
      .to eq([['a', [nil, ['a', [nil]], ['b',[nil]]] ]])
  end

  it "don't need to be started with single-character words" do
    states = Builder.add_to_tree("CA")
    expect(states).to eq([['C', [['A',[nil]]] ]])
    Builder.add_to_tree("CT",states)
    expect(states).to eq([[ 'C', [['A',[nil]],['T',[nil]]] ]])

    catcar = Builder.add_to_tree("cat")
    expect(catcar).to eq([['c', [['a', [['t',[nil]]] ]] ]])
    expect(Builder.add_to_tree("car",catcar))
      .to eq([['c', [['a', [['t',[nil]], ['r',[nil]]] ]] ]])
  end

  it "can extend themselves longer words" do
    expected = [['c', [['a', [['t', [nil,['s',[nil] ]] ]] ]] ]]

    a = Builder.add_to_tree("cat")
    expect(Builder.add_to_tree("cats",a)).to eq(expected)
  end

  it "don't change if you add the same word twice" do
    expected = [['c', [['a', [['r', [nil, ['t',[nil]]] ]] ]] ]]

    a = Builder.add_to_tree("car")
    Builder.add_to_tree("cart",a)
    expect(Builder.add_to_tree("cart",a)).to eq(expected)
  end

  it "incorporate sub-words" do
    # have to show that both "car" and "cart are in the tree (for
    # later traversal).
    initial  = [[ 'c', [['a', [['r', [['t',[nil]]] ]] ]] ]]
    expected = [[ 'c', [['a', [['r', [['t',[nil]],nil] ]] ]] ]]
    a = Builder.add_to_tree("cart")
    expect(a).to eq(initial)
    expect(Builder.add_to_tree("car",a)).to eq(expected)
  end

  context "instances" do
    before :each do
      @leaf = ['a',[nil]]
      @branch = ['a',[['b',[nil]],['a',[nil]]]]
    end

    it "know their :value and :children" do
      expect(@leaf).to respond_to(:value)
      expect(@leaf).to respond_to(:children)
      expect(@branch).to respond_to(:value)
      expect(@branch).to respond_to(:children)

      expect(@leaf.value).to eq('a')
      expect(@branch.value).to eq('a')

      expect(@leaf.has_children?).to eq(true)
      expect(@branch.has_children?).to eq(true)

      expect(@leaf.children).to eq([nil])
      expect(@branch.children).to eq([['b',[nil]],['a',[nil]]])
    end

    it "know if they are a stem, leaf, branch, or word ending" do
      expect(@leaf.is_leaf?).to eq(true)
      expect(@leaf.word_ending?).to eq(true)
      @branch.children.each { |child| expect(child.word_ending?).to eq(true) }
    end
  end
end

describe "Abbrev::Builder abbreviations" do
  a = [['a',[nil]]]
  # tree containing "a", "aa" and "ab". Should generate:
  # { "a"  => "a",
  #   "aa" => "aa",
  #   "ab" => "ab", }
  a_aa_ab = [['a', [nil,['a',[nil]],['b',[nil]]] ]]
  carcat = [['c', [['a', [['r',[nil]],['t',[nil]]] ]] ]]
  carcart = [['c', [['a', [['r',[nil,['t',[nil]]]]] ]] ]]

  it "are extracted from trees" do
    expect(Builder.abbrevs_of(a)['a']).to eq('a')
  end

  it "are built from trees" do
    expect(Builder.abbrevs_of(carcat)['car']).to eq('car')
    expect(Builder.abbrevs_of(carcat)['cat']).to eq('cat')
    expect(Builder.abbrevs_of(carcart)['car']).to eq('car')
    expect(Builder.abbrevs_of(carcart)['cart']).to eq('cart')
  end

  it "are generated as a whole" do
    abbrevs = Builder.abbrevs_of(a_aa_ab)
    expect(abbrevs['a']).to eq('a')
    expect(abbrevs['aa']).to eq('aa')
    expect(abbrevs['ab']).to eq('ab')
  end
end
