import pytest
from app import create_app, db
from app.models import Task

# Fixture for Flask test client with isolated in-memory DB
@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['API_KEY'] = 'test-key'
    # Pass config overrides to create_app BEFORE SQLAlchemy initializes
    app = create_app({
        'TESTING': True,
        'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:',
        'API_KEY': 'test-key',
        'LOG_LEVEL': 'INFO'  # or 'DEBUG' if you want
    })
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()  # fresh tables
        yield client
        with app.app_context():
            db.session.remove()
            db.drop_all()  # clean up after each test

# --- Tests ---
def test_health_check(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'ok'

def test_create_task_no_auth(client):
    response = client.post('/api/v1/tasks', json={'title': 'Test Task'})
    assert response.status_code == 401

def test_create_task_auth(client):
    response = client.post('/api/v1/tasks', 
                           json={'title': 'Test Task'},
                           headers={'X-API-Key': 'test-key'})
    assert response.status_code == 201
    assert response.json['title'] == 'Test Task'

def test_get_tasks_auth(client):
    client.post('/api/v1/tasks', 
                json={'title': 'Test Task'},
                headers={'X-API-Key': 'test-key'})
    
    response = client.get('/api/v1/tasks', headers={'X-API-Key': 'test-key'})
    assert response.status_code == 200
    assert len(response.json) == 1
