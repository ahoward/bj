class Bj
  module ClassMethods
    fattr("rails_root"){ Util.const_or_env("RAILS_ROOT"){ "." } }
    fattr("rails_env"){ Util.const_or_env("RAILS_ENV"){ "development" } }
    fattr("database_yml"){ File.join rails_root, "config", "database.yml" }
    fattr("configurations"){ YAML::load(ERB.new(IO.read(database_yml)).result) }
    fattr("tables"){ Table.list }
    fattr("hostname"){ Socket.gethostname }
    fattr("logger"){ Bj::Logger.off STDERR }
    fattr("ruby"){ Util.which_ruby }
    fattr("rake"){ Util.which_rake }
    fattr("script"){ Util.find_script "bj" }
    fattr("ttl"){ Integer(Bj::Table::Config["ttl"] || (twenty_four_hours = 24 * 60 * 60)) }
    fattr("table"){ Table }
    fattr("config"){ table.config }
    fattr("util"){ Util }
    fattr("runner"){ Runner }
    fattr("joblist"){ Joblist }
    fattr("default_path"){ %w'/bin /usr/bin /usr/local/bin /opt/local/bin'.join(File::PATH_SEPARATOR) }

    def transaction options = {}, &block
      options.to_options!

      cur_rails_env = Bj.rails_env.to_s
      new_rails_env = options[:rails_env].to_s

      cur_spec = configurations[cur_rails_env]
      table.establish_connection(cur_spec) unless table.connected?

      if(new_rails_env.empty? or cur_rails_env == new_rails_env) 
        table.transaction{ block.call(table.connection) }
      else
        new_spec = configurations[new_rails_env]
        table.establish_connection(new_spec)
        Bj.rails_env = new_rails_env
        begin
          table.transaction{ block.call(table.connection) }
        ensure
          table.establish_connection(cur_spec)
          Bj.rails_env = cur_rails_env
        end
      end
    end

    def chroot options = {}, &block
      if defined? @chrooted and @chrooted
        return(block ? block.call(@chrooted) : @chrooted)
      end
      if block
        begin
          chrooted = @chrooted
          Dir.chdir(@chrooted = rails_root) do
            raise RailsRoot, "<#{ Dir.pwd }> is not a rails root" unless Util.valid_rails_root?(Dir.pwd)
            block.call(@chrooted)
          end
        ensure
          @chrooted = chrooted 
        end
      else
        Dir.chdir(@chrooted = rails_root)
        raise RailsRoot, "<#{ Dir.pwd }> is not a rails root" unless Util.valid_rails_root?(Dir.pwd)
        @chrooted
      end
    end

    def boot
      load File.join(rails_root, "config", "boot.rb")
      load File.join(rails_root, "config", "environment.rb")
    end
  end
  send :extend, ClassMethods
end
