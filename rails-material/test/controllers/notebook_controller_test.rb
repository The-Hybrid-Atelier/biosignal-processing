require 'test_helper'

class NotebookControllerTest < ActionDispatch::IntegrationTest
  test "should get tools_and_materials" do
    get notebook_tools_and_materials_url
    assert_response :success
  end

end
