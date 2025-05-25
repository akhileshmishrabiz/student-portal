# init_db.py - Standalone database initialization script
import os
import sys
sys.path.append('/app')

from app import create_app, db

def init_database():
    """Initialize database with proper error handling"""
    app = create_app()
    
    with app.app_context():
        try:
            # Drop all tables first (optional - remove if you want to preserve data)
            # db.drop_all()
            
            # Create all tables
            db.create_all()
            
            # Verify tables were created
            from sqlalchemy import inspect
            inspector = inspect(db.engine)
            tables = inspector.get_table_names()
            
            print(f"✅ Database initialized successfully!")
            print(f"📋 Created tables: {', '.join(tables)}")
            
            return True
            
        except Exception as e:
            print(f"❌ Error initializing database: {e}")
            return False

if __name__ == "__main__":
    success = init_database()
    sys.exit(0 if success else 1)