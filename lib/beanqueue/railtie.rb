module Rails
  module Beanqueue
    class Railtie < Rails::Railtie
      initializer "load YAML config" do
        ::Beanqueue.connect ::Beanqueue.get_params(Rails.root.join('config', 'beanstalk.yml'))
      end
    end
  end
end
