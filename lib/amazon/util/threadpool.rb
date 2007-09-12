# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'thread'

module Amazon
module Util
  
class ThreadPool

  def initialize( num_threads )
    @work = Queue.new
    @threads = ThreadGroup.new
    num_threads.times do
      worker_thread = Thread.new { workerProcess }
      @threads.add worker_thread
    end
  end

  def workerProcess
    begin
      workitem = @work.pop
      return if workitem == :Die
      begin
        workitem.block.call( *workitem.args )
      rescue Exception => e
        print "Worker thread has thrown an exception: "+e.to_s+"\n"
      end
    end until false
  end

  def addWork( *args, &block )
    @work.push( WorkItem.new( args, &block ) )
  end

  def noMoreWork
    @threads.list.length.times { @work << :Die }
  end

  def join
    @threads.list.each do |t|
      t.join
    end
  end

  def finish
    noMoreWork
    join
  end

  class WorkItem
    attr_reader :args, :block
    def initialize( args, &block )
      @args = args
      @block = block
    end
  end

end # ThreadPool

end # Amazon::Util
end # Amazon
