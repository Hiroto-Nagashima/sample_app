require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  # deliveriesは変数なので、setupメソッドでこれを初期化しておかないと、並行して行われる他のテストでメールが配信されたときにエラーが発生してしまいます
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
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
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end
  
  test "valid signup information with account activation" do
    get signup_path
     # このメソッドは第一引数に文字列（'User.count'）を取り、assert_differenceブロック内の処理を実行する直前と、実行した直後のUser.countの値を比較します。
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # 有効化していない状態でログインしてみる
    log_in_as(user)
    assert_not is_logged_in?
    # 有効化トークンが不正な場合
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not is_logged_in?
    # トークンは正しいがメールアドレスが無効な場合
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?
    # 有効化トークンが正しい場合
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    # POSTリクエストを送信した結果を見て、指定されたリダイレクト先に移動するメソッド
    # 新規登録後にshowページに行ってログイン状態になる
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end
end
