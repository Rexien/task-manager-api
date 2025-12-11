from flask import Blueprint, jsonify, request, current_app
from app import db
from app.models import Task
from app.auth import require_api_key
import logging
import json

main_bp = Blueprint('main', __name__)

@main_bp.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "ok", 
        "database": "connected" # In a real app, actually check DB connection
    }), 200

@main_bp.route('/api/v1/tasks', methods=['GET'])
@require_api_key
def get_tasks():
    tasks = Task.query.all()
    return jsonify([task.to_dict() for task in tasks]), 200

@main_bp.route('/api/v1/tasks', methods=['POST'])
@require_api_key
def create_task():
    data = request.get_json()
    if not data or 'title' not in data:
        return jsonify({"error": "Title is required"}), 400
    
    new_task = Task(
        title=data['title'],
        description=data.get('description'),
        status=data.get('status', 'pending')
    )
    db.session.add(new_task)
    db.session.commit()
    
    current_app.logger.info(json.dumps({
        "event": "task_created",
        "task_id": new_task.id,
        "title": new_task.title
    }))

    return jsonify(new_task.to_dict()), 201

@main_bp.route('/api/v1/tasks/<int:id>', methods=['GET'])
@require_api_key
def get_task(id):
    task = Task.query.get_or_404(id)
    return jsonify(task.to_dict()), 200

@main_bp.route('/api/v1/tasks/<int:id>', methods=['PUT'])
@require_api_key
def update_task(id):
    task = Task.query.get_or_404(id)
    data = request.get_json()
    
    task.title = data.get('title', task.title)
    task.description = data.get('description', task.description)
    task.status = data.get('status', task.status)
    
    db.session.commit()
    return jsonify(task.to_dict()), 200

@main_bp.route('/api/v1/tasks/<int:id>', methods=['DELETE'])
@require_api_key
def delete_task(id):
    task = Task.query.get_or_404(id)
    db.session.delete(task)
    db.session.commit()
    return jsonify({"message": "Task deleted"}), 200
