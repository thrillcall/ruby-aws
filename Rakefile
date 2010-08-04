# -*- ruby -*-
 
require 'rubygems'
require 'hoe'
require './lib/ruby-aws/version.rb'
 
Hoe.plugin :git
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

# vim: syntax=ruby
