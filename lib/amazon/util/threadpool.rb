# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'thread'
require 'set'

module Amazon
module Util
  
class ThreadPool

  def initialize( num_threads, exception_handler=nil )
    @work = Queue.new
    @threads = ThreadGroup.new
    num_threads.times do
      worker_thread = Thread.new { workerProcess(exception_handler) }
      @threads.add worker_thread
    end
  end

  def workerProcess( exception_handler=nil )
    begin
      workitem = @work.pop
      return if workitem == :Die
      begin
        workitem.block.call( *workitem.args )
      rescue Exception => e
        if exception_handler.nil?
          print "Worker thread has thrown an exception: "+e.to_s+"\n"
        else
          exception_handler.call(workitem)
        end
      end
    end until false
  end

  def addWork( *args, &block )
    @work.push( WorkItem.new( args, &block ) )
  end

  def threadcount
    @threads.list.length
  end

  def noMoreWork
    threadcount.times { @work << :Die }
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

  def sync
    q = Queue.new
    s = Set.new
    t = threadcount

    t.times do
      addWork do
        q << Thread.current
        sleep(0.1) until s.size >= t
      end
    end

    s << q.pop until s.size >= t
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
