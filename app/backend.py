
from flask import Flask, jsonify, request
from flask_cors import CORS
import subprocess
import os
import logging


app = Flask(__name__)
CORS(app)

@app.route('/fetch_tag', methods=['POST'])
def fetch_tag():
    repo_path = request.json.get('path', os.getcwd())
    tag = request.json.get('tag')
    if not tag:
        return jsonify({'error': 'Missing tag parameter'}), 400
    if not os.path.isdir(repo_path):
        return jsonify({'error': f'Path not found: {repo_path}'}), 400
    try:
        # Fetch the tag from remote
        fetch_output = subprocess.check_output([
            'git', '-C', repo_path, 'artifact', 'fetch-co', '-t', f'{tag}'
        ], stderr=subprocess.STDOUT).decode('utf-8')
        # Optionally, check if the tag now exists
        tag_list = subprocess.check_output([
            'git', '-C', repo_path, 'tag', '-l', tag
        ], stderr=subprocess.STDOUT).decode('utf-8').strip().split('\n')
        found = tag in tag_list
        return jsonify({'fetched': found, 'output': fetch_output})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.output.decode('utf-8') if e.output else str(e)}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Endpoint to get info about a specific tag
@app.route('/tag_info', methods=['GET'])
def tag_info():
    repo_path = request.args.get('path', os.getcwd())
    tag_info = request.args.get('tag')
    if not tag_info:
        return jsonify({'error': 'Missing tag parameter'}), 400
    if not os.path.isdir(repo_path):
        return jsonify({'error': f'Path not found: {repo_path}'}), 400
    try:
        # Example: get the commit hash and message for the tag
        tag = tag_info.split(' ')[0]
        app.logger.debug(f"Tag: {tag}")
        output = subprocess.check_output([
            'git', '-C', repo_path, 'tag', '-l', f'{tag}',
            '--format=%(objectname)%00%(taggername)%00%(taggerdate)%00%(subject)'
        ], stderr=subprocess.STDOUT).decode('utf-8').strip()
        if not output:
            return jsonify({'errosr': f'Tag not found: {tag}'}), 404
        app.logger.debug(f"outpout: {output}")
        parts = output.split('\x00')
        info = {
            'commit': parts[0] if len(parts) > 0 else '',
            'tagger': parts[1] if len(parts) > 1 else '',
            'date': parts[2] if len(parts) > 2 else '',
            'subject': parts[3] if len(parts) > 3 else '',
        }
        return jsonify({'tag': tag, 'info': info})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.output.decode('utf-8') if e.output else str(e)}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500
def build_tag_tree(tags, delimiter='/'):
    tree = {}
    for tag in tags:
        parts = tag.split(delimiter)
        node = tree
        for part in parts:
            node = node.setdefault(part, {})
    return tree

@app.route('/tags')
def get_tags():
    repo_path = request.args.get('path', os.getcwd())
    glob_pattern = request.args.get('glob', '*')
    if not os.path.isdir(repo_path):
        return jsonify({'error': f'Path not found: {repo_path}'}), 400
    try:
        output = subprocess.check_output(['git', '-C', repo_path, 'artifact', 'list', '-g', glob_pattern], stderr=subprocess.STDOUT).decode('utf-8')
        tags = [line.strip() for line in output.splitlines() if line.strip()]
        app.logger.debug(f"Repo path: {repo_path}")
        app.logger.debug(f"Glob pattern: {glob_pattern}")
        app.logger.debug(f"Raw git output: {output}")
        app.logger.debug(f"Parsed tags: {tags}")
        tree = build_tag_tree(tags)
        app.logger.debug(f"Tag tree: {tree}")
        return jsonify({'tags': tags, 'tree': tree})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': e.output.decode('utf-8') if e.output else str(e)}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    import sys
    debug = '--debug' in sys.argv
    port = 8000
    for arg in sys.argv:
        if arg.startswith('--port='):
            try:
                port = int(arg.split('=')[1])
            except Exception:
                pass
    app.run(host='0.0.0.0', port=port, debug=debug)
