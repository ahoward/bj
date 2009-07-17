#! /usr/bin/env bacon
 


describe %/ bj / do

  it %/ should should kick arse / do
    0b101010.should.equal 42
    0x2a.should.equal 42
  end

  it %/ should load without error outside of rails / do
    should.not.raise{ require 'bj' }
  end

  it %/ needs to be installed into a RAILS_ROOT with a viable database / do
    status, stdout, stderr = Spec.runner '::ActiveRecord::Base.connection.raw_connection; puts 42'
    status.should.equal 0 
    stderr.should.equal ''
    stdout.strip.should.match %r/42/
  end

# TODO - this needs to test ./script/bj too
#
  it %/ should be installable as a plugin / do
    Dir.chdir(Spec.rails_root) do
      plugin_dir = Spec.rails_root('vendor', 'plugins')
      Spec.scrub plugin_dir 
      at_exit{ Spec.scrub plugin_dir }

      FileUtils.cp_r Spec.libdir('bj'), plugin_dir
      FileUtils.cp_r Spec.libdir('bj.rb'), plugin_dir

      status, stdout, stderr = Spec.runner <<-ruby
        require 'bj'
        p Bj
      ruby
      status.should.equal 0 
      stderr.should.equal ''
      stdout.strip.should.match %r/Bj/

      Spec.scrub plugin_dir 
    end
  end

# TODO - this needs to test ./bin/bj too
#
  it %/ should be installable as a gem / do
    Dir.chdir(Spec.rails_root) do
      gem_dir = Spec.rails_root('vendor', 'gems')
      FileUtils.mkdir_p gem_dir
      Spec.scrub gem_dir 
      at_exit{ Spec.scrub gem_dir }

      Dir.chdir(gem_dir){ FileUtils.ln_s(Spec.libdir('bj'), '.') }

      status, stdout, stderr = Spec.runner <<-ruby
        Rails.configuration.gem 'bj'
        require 'bj'
        p Bj
      ruby

       status.should.equal 0 
       stderr.should.equal ''
       stdout.strip.should.match %r/Bj/

      Spec.scrub gem_dir 
    end
  end


end



BEGIN {
  dirname, basename = File.split(File.expand_path(__FILE__))

  require File.join(dirname, 'helper.rb')
}
