# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'test/unit/testcase'
require 'ruby-aws'
require 'amazon/webservices/util/mock_transport'

class TestMockMechanicalTurkRequester < Test::Unit::TestCase

  def setup
    @mock = Amazon::WebServices::Util::MockTransport.new
    @mturk = Amazon::WebServices::MechanicalTurkRequester.new( :Transport => @mock, :AWSAccessKey => 'bogus', :AWSAccessKeyId => 'fake' )
  end

  def testGetAccountBalance
    res = @mturk.getAccountBalance # using the convenience layer method
    assert_equal nil, res
    res = @mturk.getAccountBalanceRaw({}) # using the raw method ( no default parameters )
    assert_equal nil, res
    res = @mturk.GetAccountBalance # using pass-through method ( no convenience processing )
    assert_equal true, res[:MockResult][:Mock]

    assert_equal 3, @mock.call_buffer.size
    @mock.each do |request| 
      assert_equal :GetAccountBalance, request.name
      assert request.args
      [:AWSAccessKeyId, :Signature, :Timestamp, :Request].each { |key| assert request.args[key]}
      assert_equal( {}, request.request )
    end
  end

  def testCreateHIT
    res = @mturk.createHIT # convenience layer, will auto-populate some default parameters
    res = @mturk.createHITRaw({}) # raw method, no default parameters
    res = @mturk.CreateHIT # pass-through method ( no convenience processing )

    assert_equal 3, @mock.call_buffer.size

    default_call = @mock.next # request from convenience layer
    request = default_call.request
    assert !request.keys.empty?
    expected = [:MaxAssignments, :AssignmentDurationInSeconds, :AutoApprovalDelayInSeconds, :LifetimeInSeconds, :ResponseGroup]
    assert_equal [], request.keys - expected, 'Convenience layer should not populate unexpected arguments'
    assert_equal [], expected - request.keys, 'Convenience layer should populate all expected arguments'

    @mock.each do |call|
      # both remaining calls should have no arguments
      assert_equal( {}, call.request, 'Raw calls should not auto-populate arguments')
    end
  end

  def testCreateHITs
    @mock.listen do |call|
      {:RegisterHITTypeResult => {:HITTypeId => 'specialType', :Request => {}} } if call.name == :RegisterHITType
    end

    template = { :Arg1 => 'Param2', :RequesterAnnotation => 'blub' }
    question_template = "blarg <%= @zip %> foo"
    data_set = [ { :zip => 'poodle' }, { :zip => 'fizz' } ]

    result = @mturk.createHITs( template, question_template, data_set )

    assert_equal 2, result[:Created].size
    assert_equal 0, result[:Failed].size

    register_call = @mock.next
    assert_equal :RegisterHITType, register_call.name
    assert_equal( 
                 { :MaxAssignments=>1, # default
                   :AssignmentDurationInSeconds=>3600, # default
                   :AutoApprovalDelayInSeconds=>604800, # default
                   :Arg1=>"Param2" # there's our arg!
                 },
                 register_call.request )
    expected_questions = [ "blarg poodle foo", "blarg fizz foo" ]
    @mock.each do |call|
      assert_equal :CreateHIT, call.name
      assert_equal 'specialType', call.request[:HITTypeId]
      assert_equal call.request[:Question], expected_questions.delete( call.request[:Question] )
    end
  end

  def testCreatHITsWithFailure
    @mock.listen do |call|
      raise "Mock hates you" if call.request[:Question] and call.request[:Question] =~ /poodle/
      {:RegisterHITTypeResult => {:HITTypeId => 'specialType', :Request => {}} } if call.name == :RegisterHITType
    end

    template = { :Arg1 => 'Param2', :RequesterAnnotation => 'blub' }
    question_template = "blarg <%= @zip %> foo"
    data_set = [ { :zip => 'poodle' }, { :zip => 'fizz' } ]

    result = @mturk.createHITs( template, question_template, data_set )

    assert_equal 1, result[:Created].size
    assert_equal 1, result[:Failed].size

    assert_equal "Mock hates you", result[:Failed].first[:Error]
  end

  def testGetHITResults
    # need to set up a listener to feed back hit and assignment attributes for testing results and work with pagination
    assignments_per_hit = 31
    @mock.mock_reply = {:OperationRequest => {}}
    @mock.listen do |call|
      case call.name
      when :GetHIT
        {:HIT => { :HITId => call.request[:HITId], :MockHITAttribute => 'amazing', :Request => {} } }
      when :GetAssignmentsForHIT
        size = call.request[:PageSize]
        num = call.request[:PageNumber]
        index = size * (num-1)
        max = ( assignments_per_hit > index+size ) ? index+size : assignments_per_hit
        res = []
        index.upto(max-1) do |i|
          res << { :HITId => call.request[:HITId], :AssignmentId => i, :MockAssignmentAttribute => 'stunning' }
        end
        { :GetAssignmentsForHITResult => { :Assignment => res, :Request => {} } }
      else
        nil
      end
    end

    list = %w( hitid1 hitid2 amazinghit3 lamehit4 ).collect {|id| { :HITId => id } }
    results = @mturk.getHITResults( list )

    assert_equal assignments_per_hit*list.size, results.size
    results.each { |item|
      assert_not_nil item[:HITId]
      assert_equal 'amazing', item[:MockHITAttribute]
      assert_not_nil item[:AssignmentId]
      assert_equal 'stunning', item[:MockAssignmentAttribute]
    }

  end

  def testAvailableFunds
    # TODO
  end

end
