require 'test_helper'
class UsersSignupTest < ActionDispatch::IntegrationTest
test "invalid signup information" do
get signup_path
assert_no_difference 'User.count' do
post users_path, params: { user: { name: "",
email: "user@invalid",
password:
"foo",
password_confirmation: "bar" } }
end
assert_response :success # render 'new' returns 200 in Rails 7.2
assert_select 'form[action="/users"]'
end
end
