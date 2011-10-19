require 'test/unit'
require File.dirname(__FILE__) + '/../lib/beanqueue'

puts 'Be sure to set up beanstalk daemon on localhost:11300, also be sure to clean all queues'

class TestBeanqueue < Test::Unit::TestCase

  def setup
  end
  
  def test_connect
    conn = Beanqueue.connect 'localhost:11300'
    assert conn && conn.instance_eval { @connections['localhost:11300'] }, 'connection should be set up'
    puts conn
  end

  def test_load
    conn = Beanqueue.load File.expand_path('../configs/one.yml', __FILE__)
    assert conn && conn.instance_eval { @connections['localhost:11300'] }, 'connection from one-node YAML config should be set up'

    conn = Beanqueue.load File.expand_path('../configs/many.yml', __FILE__)
    assert conn && conn.instance_eval { @connections['localhost:11300'] }, 'connection from many-nodes YAML config should be set up'
  end

  def test_push
    conn_receiver = Beanstalk::Pool.new ['localhost:11300']
    conn = Beanqueue.connect 'localhost:11300'
    Beanqueue.push 'some.job'

    conn_receiver.watch 'some.job'

    job = nil
    assert_nothing_raised do
      job = conn_receiver.reserve(2)
    end
    job.delete
    
    Beanqueue.push 'some.job', param1: 'val1', param2: 666, 'param3' => true
    job = conn_receiver.reserve(2)
    args = YAML.load(job.body)
    assert_equal({ param1: 'val1', param2: 666, 'param3' => true }, args, 'arguments are stored incorrectly')
    job.delete

    Beanqueue.push 'some.job', {}, fork: true, delay: 2, timeout: 300, priority: 100
    job = conn_receiver.reserve(3)
    assert_equal({ '__fork__' => true }, YAML.load(job.body), 'fork param is not stored')
    assert_equal 2, job.delay, 'delay is not stored'
    assert_equal 300, job.ttr, 'ttr is not stored'
    assert_equal 100, job.pri, 'pri is not stored'
    job.delete
  end
end
