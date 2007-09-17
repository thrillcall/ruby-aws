# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'thread'
require 'set'

module Amazon
module Util

# ThreadPool is a generic threadpooling class that enables
# easier multithreaded workflows.  Initialize with a thread count,
# then addWork to queue up tasks.  You can +sync+ to ensure the current
# workload is complete, or +finish+ to flush the threads when you're done.
class ThreadPool

  # First arg is the thread count.  Threads will be created once and wait
  # for work ( no performance penalty, since they're waiting on a a Queue.
  # Second arg (optional) is a proc to be used as an exception handler. If
  # this argument is passed in and the thread encounters an uncaught
  # exception, the proc will be called with the exception as the only argument.
  def initialize( num_threads, exception_handler=nil )
    @work = Queue.new
    @threads = ThreadGroup.new
    num_threads.times do
      worker_thread = Thread.new { workerProcess(exception_handler) }
      @threads.add worker_thread
    end
  end

  # add work to the queue
  # pass any number of arguments, they will be passed on to the block.
  def addWork( *args, &block )
    @work.push( WorkItem.new( args, &block ) )
  end

  def threadcount
    @threads.list.length
  end

  # kill all the threads
  def noMoreWork
    threadcount.times { @work << :Die }
  end

  # kill all threads and wait for them to die
  def finish
    noMoreWork
    @threads.list.each do |t|
      t.join
    end
  end

  # wait for the currently queued work to finish
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

  private

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
