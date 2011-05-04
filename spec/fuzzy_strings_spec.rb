require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "FuzzyStrings" do
  before(:all) do
    @fs = FuzzyStrings.new("pattern")
  end

  it "matches equal strings with 0 costs" do
    match = @fs.compare("pattern")
    match.cost.should == 0
  end

  it "matches 1 transposition and 2 substitutions on 'pattren'" do
    match = @fs.compare("pattren")
    match.substitutions.should == 2
    match.transpositions.should == 1
    match.insertions.should == 0
    match.deletions.should == 0
  end

  it "matches 2 deletions on 'patterned'" do
    match = @fs.compare("patterned")
    match.substitutions.should == 0
    match.transpositions.should == 0
    match.insertions.should == 0
    match.deletions.should == 2
  end

  it "matches 1 insertions on 'patten'" do
    match = @fs.compare("patten")
    match.substitutions.should == 0
    match.transpositions.should == 0
    match.insertions.should == 1
    match.deletions.should == 0
  end

  # 1 del, 1 sub
  it "matches on 'patterer' with a max of 2" do
    match = @fs.compare('patterer')
    match.match?(:max => 2).should == true
    match.match?(:max => 0).should == false
  end

  # 4 del
  it "does not match 'patternless' with a max of 3" do
    match = @fs.compare("patternless")
    match.match?(:max => 3).should == false
  end

  # 1 del, 5 subst
  it "does not match 'pappadums' with a max of 2" do
    match = @fs.compare("papadums")
    match.match?(:max => 2).should == false
  end

  # :-)
  it "does go well with the chicken!" do
    match = @fs.compare("chicken")
    match.match?.should == false
  end

  it "does extended matching 1" do
    match = @fs.compare('papadums')
    match.match?(:deletions => 1, :substitutions => 5).should == true
    match.match?(:deletions => 0).should == false
  end

  it "does extended matching 2" do
    match = @fs.compare('ptatenr')
    match.match?(:substitutions => 4, :transpositions => 1).should == false
    match.match?(:substitutions => 2, :transpositions => 2).should == false
    match.match?(:substitutions => 4, :transpositions => 2).should == true
  end

  it "does extended matching 2" do
    match = @fs.compare('patat')
    match.match?(:insertions => 2, :substitutions => 2).should == true
    match.match?(:insertions => 1).should == false
  end
end
