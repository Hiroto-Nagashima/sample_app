class User < ApplicationRecord
  has_many :microposts , dependent: :destroy
  # follower_idでつながっている。followingからみたrelationship
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  # followed_idでつながっている。followerからみたrelationship                               
  has_many :passive_relationships, class_name:  "Relationship",
                                  foreign_key: "followed_id",
                                  dependent:   :destroy
  # source followed_idを使って対象のユーザーを取得　
  has_many :following, through: :active_relationships, source: :followed
  # source follower_idを使って対象のユーザーを取得　
  has_many :followers, through: :passive_relationships, source: :follower
  # user.remember_tokenメソッドを使ってトークンにアクセスできるようにしたいがトークンをデータベースに保存したくない。
  # そのため仮想の属性を作る
  attr_accessor :remember_token, :activation_token,:reset_token
  # データベース上で大文字小文字を区別させない方法は難しいので、保存する前に全部小文字にしちゃう
  before_save :downcase_email
  before_create :create_activation_digest
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
  # allow_nil: true パスワードのバリデーションに対して、空だったときの例外処理を加える
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
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
  
  
  # トークンがダイジェストと一致したらtrueを返す
  # 他の認証でも使えるように、上では2番目の引数tokenの名前を変更して一般化
  # selfは省略することもできます
  # sendを使うとシンボルと文字列どちらを使った場合でも一定の値を送れる
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end
  # アカウントを有効にする
  # selfはモデル内では必須ではない
  def activate
    # update_columnsは、モデルのコールバックやバリデーションが実行されない点がupdate_attributeと異なります
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  
  # パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # パスワード再設定のメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end
  
  # パスワード再設定の期限が切れている場合はtrueを返す
  def password_reset_expired?
    # < 記号を「〜より早い時刻」と読んでください。
    reset_sent_at < 2.hours.ago
  end
  
  def feed
    # idがエスケープされるため、SQLインジェクションを避けることができます
    # SQL文に変数を代入する場合は常にエスケープする習慣をぜひ身につけてください。
    # Micropost.where("user_id = ?", id)
    
    # 上がサブセレクトになる
    # INは：と同じで、ORはANDみたいな意味になる
    # つまりfollowed_idがuser_idのマイクロポストとuser_idがuser_idのマイクロポスト(つまりユーザー自身)を取り出す
    # _idsメソッドはidを全て取り出してくれる
    # 文字列の中で変数を使う時＃{}で式展開
    following_ids = "SELECT followed_id FROM relationships
                     WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end
  
  # ユーザーをフォローする　followingという配列の最後に引数のユーザーを追加
  def follow(other_user)
    following << other_user
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す。followingのなかに引数のuserがいたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end
  
  private
    # メールアドレスをすべて小文字にする
    def downcase_email
      self.email = email.downcase
    end
  
    # 有効化トークンとダイジェストを作成および代入する
    # ユーザーが作成される前に呼び出されるのでUser.newで新しいユーザーが定義されるとactivation_token属性やactivation_digest属性が得られるようになります。
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
