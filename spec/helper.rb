module Spec
  extend self

  require 'tempfile'
  require 'fileutils'

  @dirname, @basename = File.split(File.expand_path(__FILE__))

  attr_accessor *%w(
    dirname
    basename
  )

  @specdir = @dirname

  @tmpdir = File.join(@specdir, 'tmp')
  FileUtils.mkdir_p @tmpdir
  at_exit{ FileUtils.rm_rf @tmpdir }

  @libdir = File.join(File.dirname(@dirname), 'lib')
  ENV['RUBYLIB'] = [ @libdir, ENV['RUBYLIB'] ].compact.join(File::PATH_SEPARATOR)
  $LOAD_PATH.unshift @libdir

  @bindir = File.join(File.dirname(@dirname), 'bin')
  ENV['PATH'] = [ @bindir, ENV['PATH'] ].compact.join(File::PATH_SEPARATOR)

  @rails_root = File.join @specdir, 'rails_root'

  %w(
    specdir
    tmpdir 
    libdir
    bindir
    rails_root
  ).each do |dirvar|
    module_eval <<-code
      def #{ dirvar }(*a, &b)
        paths = [a, b && b.call].flatten.compact.map{|path| path.to_s}
        File.join @#{ dirvar }, *paths
      end
    code
  end

  def pid() @pid ||= Process.pid end

  def fu() FileUtils end

  def Spec.tmpfile(*names, &block)
    names.push pid if names.empty?
    path = tmpdir *names
    open(path, 'w') do |fd|
      fd.sync = true
      block ? block.call(fd) : fd
    end
  ensure
    fu.rm_rf path if block
  end

  def runner commands, *argv, &block
    Dir.chdir(Spec.rails_root) do
      runner = Spec.rails_root('script', 'runner')
      Spec.tmpfile do |tmp|
        tmp.puts commands
        systemu "#{ runner } #{ tmp.path.inspect }", *argv, &block
      end
    end
  end

  def scrub dir
    glob = File.join(dir, '*')
    Dir[glob].each{|entry| FileUtils.rm_rf entry}
  end

  require 'rubygems'
  require 'bacon'

  begin
    require 'systemu'
  rescue LoadError
    require libdir('systemu')
  end

  STDOUT.sync = true
  STDERR.sync = true
end
