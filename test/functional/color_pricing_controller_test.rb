require File.dirname(__FILE__) + '/../test_helper'
require 'color_pricing_controller'

# Re-raise errors caught by the controller.
class ColorPricingController; def rescue_action(e) raise e end; end

class ColorPricingControllerTest < Test::Unit::TestCase
  def setup
    @controller = ColorPricingController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
