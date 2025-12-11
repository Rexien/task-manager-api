import os

class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///tasks.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    API_KEY = os.environ.get('API_KEY', 'default-dev-key')
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
