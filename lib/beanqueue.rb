require 'beanstalk-client'

module Beanqueue
  VERSION = '0.0.1'

  class << self
    def load(yaml_path)
      config = YAML::load(open(yaml_path))
      if config['nodes']
        connect *(config['nodes'].map { |node| "#{node['host']}:#{node['port']}" })
      else
        connect "#{config['host']}:#{config['port']}"
      end
    end

    def connect(*nodes)
      @connection = Beanstalk::Pool.new nodes.to_a
    end

    def push(name, args={}, opts={})
      args['__fork__'] = opts[:fork] if opts[:fork]
      @connection.use name
      @connection.yput args, (opts[:priority] || 65536), [0, opts[:delay].to_i].max, (opts[:timeout] || 120)
    end
  end
end

if defined? Rails
  Beanqueue.load Rails.root.join('config', 'beanstalk.yml')
end
