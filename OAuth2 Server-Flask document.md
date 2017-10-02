### OAuth2服务器

一个OAuth2服务器关注如何发放授权以及如何保护资源。

注册一个OAuth provider（供应商）：

```python
from flask_oauthlib.provider import OAuth2Provider

app = Flask(__name__)
oauth = OAuth2Provider(app)
```

与其他Flask扩展一样，可以稍后传入application：

```python
oauth = OAuth2Provider()

def create_app():
    app = Flask(__name__)
    oauth.init_app(app)
    return app
```

为了实现授权流程，需要理解数据模型。

####用户（资源拥有者）

用户，或资源拥有者，一般是你网站上的注册用户，你需要设计自己的用户模型。

#### 客户端（应用程序）

客户端是想用用户资源的app。建议让用户到你的网站来注册客户端，非必须。

客户端需要包含至少一下属性：

client_id ：随机字符串

client_secret ：随机字符串

client_type ：代表它是否机密的字符串

redirect_uris ：重定向uris列表

default_redirect_uri ：重定向uris之一

default_scopes ：客户端的默认权限（以空格分隔，大小写敏感的字符串列表来表示，详见：<http://tools.ietf.org/html/rfc6749#section-3.3>）

如果实现以下这些会更好：

allowed_grant_types ：授权类型列表

allowed_response_types ：答复类型列表

validate_scopes ：验证权限的函数

一个数据模型的例子，使用SQLAlchemy（SQLAlchemy不是必须的）

```python
class Client(db.Model):
    # human readable name, not required
    name = db.Column(db.String(40))

    # human readable description, not required
    description = db.Column(db.String(400))

    # creator of the client, not required
    user_id = db.Column(db.ForeignKey('user.id'))
    # required if you need to support client credential
    user = db.relationship('User')

    client_id = db.Column(db.String(40), primary_key=True)
    client_secret = db.Column(db.String(55), unique=True, index=True,
                              nullable=False)

    # public or confidential
    is_confidential = db.Column(db.Boolean)

    _redirect_uris = db.Column(db.Text)
    _default_scopes = db.Column(db.Text)

    @property
    def client_type(self):
        if self.is_confidential:
            return 'confidential'
        return 'public'

    @property
    def redirect_uris(self):
        if self._redirect_uris:
            return self._redirect_uris.split()
        return []

    @property
    def default_redirect_uri(self):
        return self.redirect_uris[0]

    @property
    def default_scopes(self):
        if self._default_scopes:
            return self._default_scopes.split()
        return []
```

#### Grant Token

grant token在认证流程中被创建，当认证结束时销毁，将其存在缓存中会有更加的性能。

grant token应该包含至少这些信息：

client_id ：client_id的随机字符串

code ：随机字符串

user ：认证用户

scopes ：权限列表

expires ：UTC时间 datetime.datetime

redirect_uri ：URI字符串

delete ：删除自身的函数

同样是SQLAlchemy模型例子（应该在缓存中）：

```python
class Grant(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    user_id = db.Column(
        db.Integer, db.ForeignKey('user.id', ondelete='CASCADE')
    )
    user = db.relationship('User')

    client_id = db.Column(
        db.String(40), db.ForeignKey('client.client_id'),
        nullable=False,
    )
    client = db.relationship('Client')

    code = db.Column(db.String(255), index=True, nullable=False)

    redirect_uri = db.Column(db.String(255))
    expires = db.Column(db.DateTime)

    _scopes = db.Column(db.Text)

    def delete(self):
        db.session.delete(self)
        db.session.commit()
        return self

    @property
    def scopes(self):
        if self._scopes:
            return self._scopes.split()
        return []
```

#### Bearer Token

bearer token是最终客户端使用的token。也有别的token类型，但bearer token广泛使用。Flask-OAuthlib只支持bearer token。

bearer token至少需要这些信息：

access_token ：字符串token

refresh_token ：字符串token

client_id ：客户端id

scopes ：权限列表

expires ：datetime.datetime对象

user ：用户对象

delete 删除自身的函数

SQLAlchemy数据模型的例子：

```python
class Token(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    client_id = db.Column(
        db.String(40), db.ForeignKey('client.client_id'),
        nullable=False,
    )
    client = db.relationship('Client')

    user_id = db.Column(
        db.Integer, db.ForeignKey('user.id')
    )
    user = db.relationship('User')

    # currently only bearer is supported
    token_type = db.Column(db.String(40))

    access_token = db.Column(db.String(255), unique=True)
    refresh_token = db.Column(db.String(255), unique=True)
    expires = db.Column(db.DateTime)
    _scopes = db.Column(db.Text)

    def delete(self):
        db.session.delete(self)
        db.session.commit()
        return self

    @property
    def scopes(self):
        if self._scopes:
            return self._scopes.split()
        return []
```

#### 配置

Oauth provider有一些内置默认值。可以用Flask配置改变它们：

| OAUTH2_PROVIDER_ERROR_URI        | The error page when there is an error, default value is '/oauth/errors'. |
| -------------------------------- | :--------------------------------------- |
| OAUTH2_PROVIDER_ERROR_ENDPOINT   | You can also configure the error page uri with an endpoint name. |
| OAUTH2_PROVIDER_TOKEN_EXPIRES_IN | Default Bearer token expires time, default is 3600. |

####实现

授权流程需要两个handler：一个是授权handler让用户确认授予，另一个是token handler让客户端交换刷新access token。

在实现授权和token handler前，要先设置getter和setter来与数据库交流。

客户端getter

须要一个客户端getter。来辨别是哪个客户端发来的请求，用decorator创建getter：

```python
@oauth.clientgetter
def load_client(client_id):
    return Client.query.filter_by(client_id=client_id).first()
```

授权getter和setter

须要授权getter和setter。用于授权流程中。用decorator实现：

```python
from datetime import datetime, timedelta

@oauth.grantgetter
def load_grant(client_id, code):
    return Grant.query.filter_by(client_id=client_id, code=code).first()

@oauth.grantsetter
def save_grant(client_id, code, request, *args, **kwargs):
    # decide the expires time yourself
    expires = datetime.utcnow() + timedelta(seconds=100)
    grant = Grant(
        client_id=client_id,
        code=code['code'],
        redirect_uri=request.redirect_uri,
        _scopes=' '.join(request.scopes),
        user=get_current_user(),
        expires=expires
    )
    db.session.add(grant)
    db.session.commit()
    return grant
```

在样例代码中有一个get_current_user方法返回当前用户对象。须要自己实现。

request对象有OAuthlib定义。你能获取至少这些信息：

client ：客户端模型对象

scopes ：权限列表

user ： 用户模型对象

redirect_uri ：重定向uri参数

header ：请求的头部

body ：请求的身体内容

state ：状态参数

response_type ：回复类型参数

Token getter和setter

必须有token getter和setter。用于授权流程和获取资源流程。用decorator实现如下：

```python
@oauth.tokengetter
def load_token(access_token=None, refresh_token=None):
    if access_token:
        return Token.query.filter_by(access_token=access_token).first()
    elif refresh_token:
        return Token.query.filter_by(refresh_token=refresh_token).first()

from datetime import datetime, timedelta

@oauth.tokensetter
def save_token(token, request, *args, **kwargs):
    toks = Token.query.filter_by(client_id=request.client.client_id,
                                 user_id=request.user.id)
    # make sure that every client has only one token connected to a user
    for t in toks:
        db.session.delete(t)

    expires_in = token.get('expires_in')
    expires = datetime.utcnow() + timedelta(seconds=expires_in)

    tok = Token(
        access_token=token['access_token'],
        refresh_token=token['refresh_token'],
        token_type=token['token_type'],
        _scopes=token['scope'],
        expires=expires,
        client_id=request.client.client_id,
        user_id=request.user.id,
    )
    db.session.add(tok)
    db.session.commit()
    return tok
```

getter收到两个参数。如果不需要支持refresh token，可以只获取access token。

setter接受token和请求参数。token是个字典，包含：

```python
{
    u'access_token': u'6JwgO77PApxsFCU8Quz0pnL9s23016',
    u'refresh_token': u'7cYSMmBg4T7F4kwoWfUQA99J8yqjp0',
    u'token_type': u'Bearer',
    u'expires_in': 3600,
    u'scope': u'email address'
}
```

请求如同授权 setter中是一个对象。

#### 用户getter

用户getter是可选的。只在你需要密码凭证授权时需要：

```python
@oauth.usergetter
def get_user(username, password, *args, **kwargs):
    user = User.query.filter_by(username=username).first()
    if user.check_password(password):
        return user
    return None
```

#### 授权handler

授权handler是为授权终点的decorator。建议这样实现：

```python
@app.route('/oauth/authorize', methods=['GET', 'POST'])
@require_login
@oauth.authorize_handler
def authorize(*args, **kwargs):
    if request.method == 'GET':
        client_id = kwargs.get('client_id')
        client = Client.query.filter_by(client_id=client_id).first()
        kwargs['client'] = client
        return render_template('oauthorize.html', **kwargs)

    confirm = request.form.get('confirm', 'no')
    return confirm == 'yes'
```

GET请求会渲染一个页面让用户确认授权，kwargs参数是：

client_id ：客户端id

scope ：权限列表

state ：状态参数

redirect_uri ：重定向uri参数

response_type ：回复类型参数

POST请求需要返回一个布尔值来表示用户是否授权访问。

示例代码中有一个@require_login decorator你需要自己实现它。

Token handler

token handler是用来交换刷新access token的decorator。不需要做太多：

```python
@app.route('/oauth/token')
@oauth.token_handler
def access_token():
    return None
```

在token回复时可以添加更多的数据：

```python
@app.route('/oauth/token')
@oauth.token_handler
def access_token():
    return {'version': '0.1.0'}
```

Flask route限制HTTP访问的类型，例如，只允许用POST交换token：

```python
@app.route('/oauth/token', methods=['POST'])
@oauth.token_handler
def access_token():
    return None
```

认证流程已经完成，现在所有都应该起作用了。

废除handler

有时用户希望废除给一些app的授权。废除handler是app程序化的废除已经授予的授权。一样不用实现太多，同样推荐仅限POST：

```python
@app.route('/oauth/revoke', methods=['POST'])
@oauth.revoke_handler
def revoke_token(): pass
```

子类方式

如果你对decorator方式的getter和setter不满意。也可以用子类的方式实现：

```python
class MyProvider(OAuth2Provider):
    def _clientgetter(self, client_id):
        return Client.query.filter_by(client_id=client_id).first()

    #: more getters and setters
```

所有的getter和setter都以_开始命名。

#### 保护资源

用requite_oauth decorator来保护用户的资源：

```python
@app.route('/api/me')
@oauth.require_oauth('email')
def me():
    user = request.oauth.user
    return jsonify(email=user.email, username=user.username)

@app.route('/api/user/<username>')
@oauth.require_oauth('email')
def user(username):
    user = User.query.filter_by(username=username).first()
    return jsonify(email=user.email, username=user.username)
```

decorator接受权限列表，只有赋予此权限的客户端可以访问这一资源。

0.5.0版本中的改动

oauth request有额外的属性，包含至少：

client ：客户端模型对象

scopes ：权限列表

user ： 用户模型对象

redirect_uri ：重定向uri参数

header ：请求的头部

body ：请求的身体内容

state ：状态参数

response_type ：回复类型参数



### OAuth2的例子

tests文件夹中可以找到示例服务器（和客户端）：<https://github.com/lepture/flask-oauthlib/tree/master/tests/oauth2>

其他有帮助的资源有：

另一个OAuth2服务器的例子：<https://github.com/lepture/example-oauth2-server>

一篇关于如何创建OAuth服务器的文章：<http://lepture.com/en/2013/create-oauth-server>

