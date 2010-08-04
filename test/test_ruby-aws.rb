# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'test/unit'
require 'ruby-aws'

class TestRubyAWS < Test::Unit::TestCase

  VERSION_NUMBER_PATTERN = '\d+\.\d+\.\d+(\.[a-zA-Z\d]+)*'

  def testVersion
    assert( RubyAWS::VERSION =~ /^#{VERSION_NUMBER_PATTERN}$/ , "RubyAWS::VERSION is incorrectly formatted")
  end

  def testAgent
    assert( RubyAWS.agent =~ /^ruby-aws\/#{VERSION_NUMBER_PATTERN}$/ )
    assert( RubyAWS.agent('Tester') =~ /^ruby-aws\/#{VERSION_NUMBER_PATTERN} Tester$/ )
  end

end

