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
    @pending = [].extend(MonitorMixin)
    @gotit = @pending.new_cond
    @tp = nil
    self.flush
  end

  # clear the result set and start over again
  def flush
    @tp.finish unless @tp.nil?
    @tp = ThreadPool.new(THREADPOOL_SIZE, @eh)
    @done = false
    @pending.clear
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
    @pending.synchronize do
      "#<Amazon::Util::ProactiveResults truth_size=#{@truth.size} pending_pages=#{@pending.inspect}>"
    end
  end

  private

  def getPage(num)
    @pending.synchronize do
      @pending << num
      @tp.addWork( num ) do |page|
        worker(page)
      end
    end
  end

  def worker(page)
    begin
      res = @feeder.call( page )
    rescue Exception => e
      @pending.synchronize { @pending.delete page }
      raise e
    end
    @pending.synchronize do
      if res.nil? || res.empty?
        # we're done
      else
        @truth += res
        getPage( page + THREADPOOL_SIZE )
      end
      @pending.delete page
      @gotit.signal
    end
  end

  def feedme
    @pending.synchronize do
      current_size = @truth.size
      @gotit.wait_until { @pending.size == 0 || @truth.size > current_size }
      @done = (@pending.size == 0)
    end
  end

end

end # Amazon::Util
end # Amazon
