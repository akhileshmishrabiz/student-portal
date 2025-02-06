from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from config import Config

db = SQLAlchemy()
login_manager = LoginManager()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.secret_key = 'asdf45sfsdg777gsdg'
    
    db.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    
    with app.app_context():
        from app.routes import routes, auth
        app.register_blueprint(routes.bp)
        app.register_blueprint(auth.auth_bp)
        
    return app