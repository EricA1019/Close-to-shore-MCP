from flask import Flask, send_from_directory, jsonify, request
import os

app = Flask(__name__)

# Serve MCP docs
@app.route('/docs/<path:filename>')
def serve_docs(filename):
    docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
    return send_from_directory(docs_dir, filename)

# Status endpoint
@app.route('/status')
def status():
    return jsonify({'status': 'MCP server running', 'project': 'Godot MCP Template'})

# Feedback endpoint (stub)
@app.route('/feedback', methods=['POST'])
def feedback():
    data = request.json
    # Save feedback to file or process as needed
    return jsonify({'received': data}), 201

# Workflow endpoint (stub)
@app.route('/workflow')
def workflow():
    return jsonify({'steps': ['plan', 'test', 'implement', 'validate', 'feedback', 'document']})

if __name__ == '__main__':
    app.run(port=5000, debug=True)
