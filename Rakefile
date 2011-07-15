# -*- ruby -*-
 
require 'rubygems'
require 'hoe'
require './lib/ruby-aws/version.rb'
 
Hoe.spec 'ruby-aws' do
  self.version = RubyAWS::VERSION.dup
  self.rubyforge_name = 'ruby-aws'
  developer 'David J Parrott', 'valthon@nothlav.net'
  extra_deps << ['highline','>= 1.2.7']
  need_tar
  need_zip

  self.summary = 'Ruby libraries for working with Amazon Web Services ( Mechanical Turk )'
  self.email = 'ruby-aws-develop@rubyforge.org'
  self.url = "http://rubyforge.org/projects/ruby-aws/"
end

task :gitversion do
  gv = `git describe --dirty`.chomp.gsub(/^v/,'').gsub('-','.')
  File.open('lib/ruby-aws/version.rb', File::WRONLY | File::CREAT | File::TRUNC ) do |f|
    f << "# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.\n"
    f << "# License::   Apache License, Version 2.0\n"
    f << "\n"
    f << "module RubyAWS\n"
    f << "  VERSION = '#{gv}'.freeze\n"
    f << "end\n"
  end
end

# vim: syntax=ruby
