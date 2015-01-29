require 'rspec'
require 'abbrev_builder'

## alias the class so we don't have to wear our fingers down.
Builder = Abbrev::Builder
describe Builder do
  before :each do
    @builder = Builder.new
  end

  it "responds to :new with an instance" do
    @builder.instance_of?(Builder).should == true
  end

  it "builds a hash of abbreviations, like abbrev" do
    @builder.build.should.respond_to? :[]
  end

  it "accepts new words" do
    @builder.add_word('new')
  end

  it "accepts new words (chainable)" do
    @builder.add_word('new')
      .instance_of?(Builder).should == true
  end

  it "generates abbreviations for words it contains" do
    @builder.add_word('new').build.assoc('n').should == 'new'
    @builder.build.keys.should include('new')
  end

  it "should be chainable" do
    @builder
      .add_word('cat')
      .add_word('car')
      .class.should == Builder
  end

  it "generates distinct abbreviations" do
    abbrevs = @builder
      .add_word('cat')
      .add_word('car')
      .add_word('cattle')
      .build
    abbrevs['catt'].should == "cattle"
    abbrevs['car'].should == "car"
  end

  # This part of the spec will have to change if I change my tree
  # representation. Is including this in my spec a mistake? Or will it
  # focus my refactoring better?
  it "generates trees from strings" do
    a = Builder.add_to_tree("a")
    a.should == [['a',[nil]]]
  end

  it "Can incorporate new strings that share a prefix" do
    a = Builder.add_to_tree("a")
    Builder.add_to_tree("aa",a).should == [['a', [nil, ['a', [nil]] ] ]]
    Builder.add_to_tree("ab",a)
      .should == [['a', [nil, ['a', [nil]], ['b',[nil]]] ]]
  end

  it "Does not need to be initialized with single characters" do
    states = Builder.add_to_tree("CA")
    states.should == [['C', [['A',[nil]]] ]]
    Builder.add_to_tree("CT",states)
    states.should == [[ 'C', [['A',[nil]],['T',[nil]]] ]]

    catcar = Builder.add_to_tree("cat")
    catcar.should == [['c', [['a', [['t',[nil]]] ]] ]]
    Builder.add_to_tree("car",catcar)
      .should == [['c', [['a', [['t',[nil]], ['r',[nil]]] ]] ]]
  end

  it "incorporates longer words" do
    expected = [['c', [['a', [['t', [nil,['s',[nil] ]] ]] ]] ]]

    a = Builder.add_to_tree("cat")
    Builder.add_to_tree("cats",a).should == expected
  end

  it "extends the tree idempotently" do
    expected = [['c', [['a', [['r', [nil, ['t',[nil]]] ]] ]] ]]

    a = Builder.add_to_tree("car")
    Builder.add_to_tree("cart",a)
    Builder.add_to_tree("cart",a).should == expected
  end

  it "incorporates sub-words" do
    # have to show that both "car" and "cart are in the tree (for
    # later traversal).
    initial  = [[ 'c', [['a', [['r', [['t',[nil]]] ]] ]] ]]
    expected = [[ 'c', [['a', [['r', [['t',[nil]],nil] ]] ]] ]]
    a = Builder.add_to_tree("cart")
    a.should == initial
    Builder.add_to_tree("car",a).should == expected
  end

  it "builds abbreviations from trees" do
    tree = [['c', [['a', [['r',[nil]],['t',[nil]]] ]] ]]
    a = Builder.abbrevs_of(tree).assoc('car').should == 'car'
  end
end
