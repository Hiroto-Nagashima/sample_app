class User < ApplicationRecord
  # user.remember_tokenメソッドを使ってトークンにアクセスできるようにしたいがトークンをデータベースに保存したくない。
  # そのため仮想の属性を作る
  attr_accessor :remember_token
  # データベース上で大文字小文字を区別させない方法は難しいので、保存する前に全部小文字にしちゃう
  before_save { self.email = email.downcase }
  validates :name,  presence: true, length: { maximum: 50 }
  # 正規表現（Regular Expression）
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  # メールアドレスの大文字小文字を無視した一意性の検証 
  # case_sensitive: falseに置き換えただけ。この場合、:uniquenessをtrueと判断します。
  # validates :email, presence: true, length: { maximum: 255 },format: { with: VALID_EMAIL_REGEX },uniqueness: { case_sensitive: false }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  # レコード作成時にはpresence:trueがかかっているが、レコード更新時にはかからない。そのため別にここでバリデーションをかける。
  validates :password, presence: true, length: { minimum: 6 }
  has_secure_password
  # bcryptパスワード作成
  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
  # 記憶トークンを作成
  def User.new_token
    # SecureRandomモジュールにあるurlsafe_base64メソッドは、A–Z、a–z、0–9、"-"、"_"のいずれかの文字（64種類）からなる長さ22のランダムな文字列を返します
    SecureRandom.urlsafe_base64
  end
  
  def remember
    # 右辺の記憶トークン（ランダムな値）を左辺のremember_token属性に代入
    self.remember_token = User.new_token
    # 記憶トークンをハッシュ化して保存/記憶ダイジェスト作成
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    # ダイジェストが存在しない場合に対応
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end
end
