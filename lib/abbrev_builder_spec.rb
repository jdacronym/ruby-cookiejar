require 'rspec'
require 'abbrev_builder'

describe Abbrev::Builder do
  before :each do
    @builder = Abbrev::Builder.new
  end

  it "responds to :new with an instance" do
    @builder.instance_of?(Abbrev::Builder).should == true
  end

  it "builds a hash of abbreviations, like abbrev" do
    @builder.build.should.respond_to? :[]
  end

  it "accepts new words" do
    @builder.add_word('new')
  end

  it "accepts new words (chainable)" do
    @builder.add_word('new')
      .instance_of?(Abbrev::Builder).should == true
  end

  it "generates abbreviations for words it contains" do
    @builder.add_word('new').build.should.include? 'n'
    @builder.build.keys.should.include? 'new'
  end

  it "should be chainable" do
    @builder
      .add_word('cat')
      .add_word('car')
      .class.should == Abbrev::Builder
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

end
