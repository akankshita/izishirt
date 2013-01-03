require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/top_design_controller'

# Re-raise errors caught by the controller.
class Admin::TopDesignController; def rescue_action(e) raise e end; end

class Admin::TopDesignControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::TopDesignController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
