# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

module RubyAWS
  SRC_PATH = " $URL$ "
  SRC_PATH =~ /tags\/(\d+\.\d+\.\d+)\/.*\/ruby-aws\/version.rb/
  SVN_VERSION = $1
  GIT_VERSION = `git describe --tags --always --dirty`.chomp.gsub(/^v/,'').gsub('-','.')
  VERSION = (SVN_VERSION || GIT_VERSION || "0.0.1").freeze
end
