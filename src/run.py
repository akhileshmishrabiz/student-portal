# run.py - Updated for production use
from app import create_app, db
import os

app = create_app()

# Initialize database tables on startup (for both dev and prod)
with app.app_context():
    try:
        db.create_all()
        print("Database tables created successfully!")
    except Exception as e:
        print(f"Error creating database tables: {e}")

if __name__ == "__main__":
    # Run in development mode only if explicitly set
    if os.getenv('FLASK_ENV') == 'development':
        app.run(debug=True, host="0.0.0.0", port=8000)
    else:
        print("Production mode: Use gunicorn to start the application")
        print("Command: gunicorn --config gunicorn.conf.py run:app")