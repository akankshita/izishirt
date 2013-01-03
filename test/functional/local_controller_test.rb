require File.dirname(__FILE__) + '/../test_helper'
require 'local_controller'

# Re-raise errors caught by the controller.
class LocalController; def rescue_action(e) raise e end; end

class LocalControllerTest < Test::Unit::TestCase
  def setup
    @controller = LocalController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
