require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  test "invalid signup information" do
    get signup_path
    # ユーザ数を覚えた後にデータを投稿してみて、ユーザ数が変わらないかどうかを検証するテスト
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name:  "",
                                         email: "user@invalid",
                                         password:              "foo",
                                         password_confirmation: "bar" } }
    end
    # newアクションが再描画されるテスト
    assert_template 'users/new'
    assert_select 'div#error_explanation'     # 1. id="error_explanationが存在するか
    assert_select 'div.alert'                            # 2.1. class="alert"が存在するか
    assert_select 'div.alert-danger'
  end
end
