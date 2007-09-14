# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'thread'
require 'amazon/util/threadpool'

module Amazon
module Util

# ProactiveResults is not as lazy as LazyResults
# The constructor takes a block which should accept a pagenumber
#  and return a page worth of results.
# note: Does not guarantee order of results
class ProactiveResults
  include Enumerable

  THREADPOOL_SIZE = 3

  def initialize( exception_handler=nil, &feeder )
    @feeder = feeder
    @eh = exception_handler
    @tp = nil
    self.flush
  end

  # clear the result set and start over again
  def flush
    @tp.finish unless @tp.nil?
    @tp = ThreadPool.new(THREADPOOL_SIZE, @eh)
    @done = false
    @pending = Queue.new
    @results = Queue.new
    @truth = []
    1.upto(THREADPOOL_SIZE) do |page|
      getPage(page)
    end
  end

  # iterate over entire result set, waiting for
  #  threads to finish where necessary
  def each( &block ) # :yields: item
    index = 0
    while true
      if index >= @truth.size
        break if @done
        feedme
      else
        yield @truth[index]
        index += 1
      end
    end
  end

  # index into the result set. if we haven't
  #  loaded enough, will wait until we have
  def []( index )
    feedme while !@done and index >= @truth.size
    return @truth[index]
  end

  # wait for the entire results set to be populated,
  #  then return an array of the results
  def to_a
    feedme until @done
    return @truth.dup
  end

  def inspect
    "#<Amazon::Util::ProactiveResults truth_size=#{@truth.size} pending_pages=#{@pending.size}>"
  end

  private

  def getPage(num)
    @pending << :something
    @tp.addWork(num) { |n| worker(n) }
  end

  def worker(page)
    res = []
    begin
      res = @feeder.call( page )
    ensure
      if res.nil? || res.empty?
        @results << []
      else
        @results << res
        getPage( page + THREADPOOL_SIZE )
      end
      @pending.pop true
    end
  end

  def feedme
    return if @done
    while true
      begin
        res = @results.pop true
        unless res.empty?
          @truth += res
          return
        end
      rescue
        if @pending.empty?
          @done = true
          return
        end
        sleep(0.1)
      end
    end
  end

end

end # Amazon::Util
end # Amazon
