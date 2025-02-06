# Testing locally
# Run PostgreSQL container
docker run -d \
 --name attendance-db \
 -e POSTGRES_PASSWORD=password \
 -e POSTGRES_DB=mydb \
 -p 5432:5432 \
 postgres:15

# Export database connection string
export DB_LINK="postgresql://postgres:password@localhost:5432/mydb"

# cd to src

cd src

# Virtual env

python3 -m venv venv

source venv/bin/activate

pip install -r requirements.txt