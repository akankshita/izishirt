require File.dirname(__FILE__) + '/../test_helper'
require 'myizishirt_controller'

# Re-raise errors caught by the controller.
class MyizishirtController; def rescue_action(e) raise e end; end

class MyizishirtControllerTest < Test::Unit::TestCase
  def setup
    @controller = MyizishirtController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
