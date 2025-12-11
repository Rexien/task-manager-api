import logging
import json
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from prometheus_flask_exporter import PrometheusMetrics
from app.config import Config

db = SQLAlchemy()
migrate = Migrate()

class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "level": record.levelname,
            "message": record.getMessage(),
            "timestamp": self.formatTime(record, self.datefmt),
            "logger": record.name
        }
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_record)

def create_app(test_config=None):
    app = Flask(__name__)
    
    if test_config:
        app.config.from_mapping(test_config)
    else:
        app.config.from_object(Config)

    db.init_app(app)
    migrate.init_app(app, db)
    
    # Initialize Prometheus Metrics
    PrometheusMetrics(app)

    # Logging Setup
    # Remove default handlers to avoid duplicate logs
    app.logger.handlers.clear()
    
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())
    app.logger.addHandler(handler)
    app.logger.setLevel(app.config.get('LOG_LEVEL', 'INFO'))

    from app.routes import main_bp
    app.register_blueprint(main_bp)

    return app
