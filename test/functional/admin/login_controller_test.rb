require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/login_controller'

# Re-raise errors caught by the controller.
class Admin::LoginController; def rescue_action(e) raise e end; end

class Admin::LoginControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
