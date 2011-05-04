# Match words based on the operations needed to get 2 similar words bt
# insertion, deletion, substitution or transposition operations.
#
# cot   => coat  (a must be inserted to get the same word)
# coat  => cot   (a must be deleted to get the same word)
# cost  => coat  (a must be substituted with s to get the same word)
# foo   => floor (l and r must be inserted)
# floor => foo   (l and r must be deleted)
# cost  => cots  (t and s must substituted (cost=2) or transpositioned (cost=1))
#
# the cost is the amount of operations needed to make 2 words the same
#
# == Usage
#   fs = FuzzyStrings.new("pattern")
#   match = fs.compare("pattren")
#   puts match.match?
#   # true
#   puts match.score
#   # 2
#   puts match
#
# == Unicode?
# It is assumed that all strings are utf-8
#
class FuzzyStrings
  def initialize(string1)
    @string1 = string1.to_s rescue ""
  end

  # compare a given string to the base pattern, the compared strings is
  # operated upon (soo cot as the pattern and coat in compare leads to deletion)
  #
  # returns a FuzzyStrings::Match object
  #
  def compare(string2, no_transpositions = false)
    @string2 = string2.to_s rescue ""
    @match   = Match.new

    return @match if @string1 == @string2

    rule = 'U*'

    sequence1 = @string1.unpack rule
    sequence2 = @string2.unpack rule

    if (sequence1 + sequence2).include?(0)
      raise ArgumentError.new(
        "Strings cannot contain NULL-bytes due to internal semantics"
      )
    end

    @short, @long = if sequence1.length < sequence2.length
      [sequence1, sequence2]
    else
      [sequence2, sequence1]
    end

    find_insertions
    find_substitutions
    find_transpositions unless no_transpositions == true

    return @match
  end

  # find insertions  (if string2 is shorter we are finding deletions)
  #
  # place null-bytes on the insert positions
  def find_insertions
    # when both are equal in length no insertions can happen
    return if @short.length == @long.length

    mode = @short.pack('U*') == @string2 ? :insertions : :deletions

    ## # don't destroy the object short'
    ## short = @short

    @long.each_with_index do |long_chr, i|
      short_chr = @short[i]
      if long_chr != short_chr
        next if @long[i+1].nil? or @long[i+1] != short_chr

        # there is an insertion
     	  @short = @short[0,i] + [ 0 ] + @short[i, @short.length-1]
        @match.send(:"#{mode}=", @match.send(mode) + 1)
      end
    end

    # pad the short with 0 until equal in length (these are not insertions)
    while @long.length > @short.length
      @short << 0
      @match.send(:"#{mode}=", @match.send(mode) + 1)
    end
  end

  # compare characters, dont compare if 1 character is a null byte
  def find_substitutions
    @short.each_with_index do |char1, i|  # .select { |c| c != 0 }
      char2 = @long[i]
      next if [ char1, char2 ].include? 0
      @match.substitutions += 1 if char1 != char2
    end
  end

  # compare characters by 2 and find transposed characters
  # (when given cost, cots, ts is transposed)
  #
  def find_transpositions
    short = @short.select { |c| c != 0 }
    short.each_index do |i|
      break if i == (short.length - 1)

      one = short[i..i+1]
      two = @long[i..i+1]
      next if one == two

      @match.transpositions += 1 if (one & two).length == 2
    end
  end

  private :find_transpositions, :find_substitutions, :find_insertions

  # A Match object holds all the costs of operations for a comparison and can
  # define a match for you
  #
  class Match
    attr_accessor :insertions, :deletions, :substitutions, :transpositions

    def initialize
      @insertions     = 0
      @deletions      = 0
      @substitutions  = 0
      @transpositions = 0
    end

    # Is it a match?
    #
    # By default checks if the cost of all the operations is no greater then 3
    #
    # == Options
    # [:score]          * Total cost of operations is no greater then X.
    #                   * If specified, doesn't check any other criterium
    # [:max]            * All of the operations must be no greater then X. So
    #                     the score may be 3, but there cant be 2 deletions if
    #                     X = 1.
    #                   * If specified, checks no other criterium.
    #                   * It checks substitutions OR transpositions
    # [:deletions]      * The amount of deletions is no greater then X
    # [:insertions]     * The amount of insertions is no greater then X
    # [:substitutions]  * The amount of substitutions is no greater then X
    #
    def match?(opts = { :score => 3 })
      if opts[:score]
        # combined operations
        self.score <= opts[:score]

      elsif opts[:max]
        !(self.deletions > opts[:max]) and !(self.insertions > opts[:max]) \
          and !(self.substitutions > opts[:max]) \
          and !(self.transpositions > opts[:max])

      else
        plausable = true

        if opts[:deletions]
          plausable &= self.deletions <= opts[:deletions]
        end
        if opts[:insertions]
          plausable &= self.insertions <= opts[:insertions]
        end
        if opts[:substitutions]
          plausable &= self.substitutions <= opts[:substitutions]
        end
        if opts[:transpositions]
          plausable &= self.transpositions <= opts[:transpositions]
        end

        plausable
      end
    end

    # the total cost of the operations
    #
    # Normaly uses substitutions (which is more expensive).
    #
    # Specify use_transpositions as true to get transposition cost instead of
    # substitutions cost
    #
    def score(use_transpositions=false)
      (use_transpositions ? transpositions : substitutions) + insertions + deletions
    end
    alias_method :cost, :score

    def to_s # :nodoc:
      "{ d: #{@deletions}, i: #{@insertions}, s: #{@substitutions}, t: #{@transpositions} }"
    end
  end

  private :find_insertions, :find_substitutions
end

# extend String
class String
  def fuzzy_match(other)
    fs = FuzzyStrings.new(self)
    fs.compare other
  end
end