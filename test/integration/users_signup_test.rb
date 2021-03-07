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
  
  test "valid signup information" do
    get signup_path
     # このメソッドは第一引数に文字列（'User.count'）を取り、assert_differenceブロック内の処理を実行する直前と、実行した直後のUser.countの値を比較します。
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    end
    # POSTリクエストを送信した結果を見て、指定されたリダイレクト先に移動するメソッド
    # 新規登録後にshowページに行ってログイン状態になる
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end
end
