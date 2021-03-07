class User < ApplicationRecord
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
  # fixture用のbcryptパスワード作成
  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
end
