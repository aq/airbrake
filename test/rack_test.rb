require File.dirname(__FILE__) + '/helper'

class RackTest < Test::Unit::TestCase

  should "call the upstream app with the environment" do
    environment = { 'key' => 'value' }
    app = lambda { |env| ['response', {}, env] }
    stack = HoptoadNotifier::Rack.new(app)

    response = stack.call(environment)

    assert_equal ['response', {}, environment], response
  end

  should "deliver an exception raised while calling an upstream app" do
    HoptoadNotifier.stubs(:notify_or_ignore)

    exception = build_exception
    app = lambda do |env|
      raise exception
    end

    begin
      stack = HoptoadNotifier::Rack.new(app)
      stack.call({})
    rescue Exception => raised
      assert_equal exception, raised
    else
      flunk "Didn't raise an exception"
    end

    assert_received(HoptoadNotifier, :notify_or_ignore) { |expect| expect.with(exception) }
  end

  should "deliver an exception in rack.exception" do
    HoptoadNotifier.stubs(:notify_or_ignore)
    exception = build_exception

    response = [200, {}, ['okay']]
    app = lambda do |env|
      env['rack.exception'] = exception
      response
    end
    stack = HoptoadNotifier::Rack.new(app)

    actual_response = stack.call({})

    assert_equal response, actual_response
    assert_received(HoptoadNotifier, :notify_or_ignore) { |expect| expect.with(exception) }
  end

end