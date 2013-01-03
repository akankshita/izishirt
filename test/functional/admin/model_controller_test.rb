require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/model_controller'

# Re-raise errors caught by the controller.
class Admin::ModelController; def rescue_action(e) raise e end; end

class Admin::ModelControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::ModelController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
