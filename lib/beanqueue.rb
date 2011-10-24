require 'beanstalk-client'

module Beanqueue
  VERSION = '0.1.2'

  class << self
    def get_params(yaml_path)
      hash = YAML.load(open(yaml_path))
      if hash['nodes']
        hash['nodes'].map { |node| "#{node['host']}:#{node['port']}" }
      else
        "#{hash['host']}:#{hash['port']}"
      end
    end      

    def connect(nodes)
      @connection = Beanstalk::Pool.new(nodes.is_a?(Array) ? nodes : [nodes])
    end

    def push(name, args={}, opts={})
      args['__fork__'] = opts[:fork] if opts[:fork]
      @connection.use name.to_s.gsub('_', '.')
      @connection.yput args, (opts[:priority] || 65536), [0, opts[:delay].to_i].max, (opts[:timeout] || 120)
    end
  end
end

if defined?(Rails)
  require "beanqueue/railtie"
end
