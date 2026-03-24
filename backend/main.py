import os
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

# Connect to the PostgreSQL database
def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        user='postgres',
        password=os.environ.get('DB_PASSWORD'),
        dbname='postgres'
    )
    return conn

@app.route('/api/status', methods=['GET'])
def status():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT NOW()')
        db_time = cur.fetchone()[0]
        cur.close()
        conn.close()
        return jsonify({"status": "Online", "db_time": str(db_time)})
    except Exception as e:
        return jsonify({"status": "DB Connection Error", "error": str(e)}), 500

if __name__ == '__main__':
    # Cloud Run requires listening on 0.0.0.0 and port 8080 by default
    app.run(host='0.0.0.0', port=8080)
