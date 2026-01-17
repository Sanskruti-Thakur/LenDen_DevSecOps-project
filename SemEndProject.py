from flask import Flask, render_template, jsonify
import socket
import os
from datetime import datetime

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/health")
def health():
    return jsonify({
        "status": "UP",
        "time": datetime.utcnow().isoformat()
    })

@app.route("/security")
def security():
    return jsonify({
        "firewall": "enabled",
        "encryption": "enabled",
        "open_ports": [5000],
        "status": "secure"
    })

@app.route("/deployment")
def deployment():
    return jsonify({
        "hostname": socket.gethostname(),
        "environment": os.getenv("ENV", "local"),
        "containerized": True
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
