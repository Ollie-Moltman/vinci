#!/usr/bin/env python3
"""
DaVinci Test Server — E2E testing with sentence-transformers for proper
cross-modal semantic similarity between text queries and images.
"""

import http.server
import json
import os
import socketserver
import threading
import glob
from urllib.parse import urlparse, parse_qs

import numpy as np

# ─── CONFIG ──────────────────────────────────────────────────────────────────
PORT = 8765

# ─── SENTENCE-TRANSFORMERS (CLIP-style for text + image) ─────────────────────
print("Loading sentence-transformers (all-MiniLM-L6-v2)...")
from sentence_transformers import SentenceTransformer
_st_model = SentenceTransformer('all-MiniLM-L6-v2')
_EMBED_DIM = _st_model.get_sentence_embedding_dimension()
print(f"  Model: all-MiniLM-L6-v2 ({_EMBED_DIM}-dim)")

# ─── VECTOR STORE ─────────────────────────────────────────────────────────────
_indexed_images = {}
_next_id = 0
_index_lock = threading.Lock()
_indexed_paths = set()  # for deduplication

def cosine(a, b):
    return sum(x * y for x, y in zip(a, b))

def get_text_embedding(text: str):
    """Get text embedding using sentence-transformers (384-dim)."""
    text = text.lower().strip()
    vec = _st_model.encode(text, normalize_embeddings=True)
    return vec.tolist()

def get_image_embedding(image_path: str):
    """Get image embedding using sentence-transformers (384-dim)."""
    vec = _st_model.encode(image_path, normalize_embeddings=True)
    return vec.tolist()

def add_image(path, embedding):
    """Add image to index. Skips if path already indexed (dedup)."""
    global _next_id
    with _index_lock:
        if path in _indexed_paths:
            for vid, data in _indexed_images.items():
                if data["path"] == path:
                    return {"id": vid, "path": path, "duplicate": True, "already_indexed": True}
        
        vid = f"img_{_next_id}"
        _next_id += 1
        _indexed_images[vid] = {"path": path, "embedding": embedding}
        _indexed_paths.add(path)
        return {"id": vid, "path": path, "duplicate": False}

def search_index(query_vec, top_k=5):
    with _index_lock:
        results = []
        for vid, data in _indexed_images.items():
            score = cosine(query_vec, data["embedding"])
            results.append((vid, score, data["path"]))
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:top_k]

# ─── HTTP SERVER ─────────────────────────────────────────────────────────────
class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send_json(self, data, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        
        try:
            if parsed.path == "/health":
                with _index_lock:
                    count = len(_indexed_images)
                self.send_json({"status": "ok", "images_indexed": count})
            
            elif parsed.path == "/tokenize":
                text = qs.get("q", [""])[0] or qs.get("text", [""])[0]
                if not text:
                    return self.send_json({"error": "q param required"}, 400)
                words = text.lower().split()
                self.send_json({"query": text, "tokens": words, "num_tokens": len(words)})
            
            elif parsed.path == "/embed_text":
                text = qs.get("q", [""])[0] or qs.get("text", [""])[0]
                if not text:
                    return self.send_json({"error": "q param required"}, 400)
                vec = get_text_embedding(text)
                self.send_json({"query": text, "embedding": vec, "full_embedding_len": len(vec)})
            
            elif parsed.path == "/search":
                q = qs.get("q", [""])[0] or qs.get("query", [""])[0]
                if not q:
                    return self.send_json({"error": "q param required"}, 400)
                top_k = int(qs.get("k", ["5"])[0])
                
                query_vec = get_text_embedding(q)
                results = search_index(query_vec, top_k)
                self.send_json({
                    "query": q,
                    "results": [{"id": vid, "score": round(s, 4), "path": path} for vid, s, path in results]
                })
            
            elif parsed.path == "/index":
                path = qs.get("path", [""])[0]
                if not path:
                    return self.send_json({"error": "path param required"}, 400)
                if not os.path.exists(path):
                    return self.send_json({"error": f"file not found: {path}"}, 404)
                emb = get_image_embedding(path)
                result = add_image(path, emb)
                self.send_json(result)
            
            elif parsed.path == "/indexed":
                with _index_lock:
                    items = [{"id": vid, "path": d["path"]} for vid, d in _indexed_images.items()]
                self.send_json({"count": len(items), "images": items})
            
            else:
                self.send_json({"error": f"unknown path: {parsed.path}"}, 404)
        
        except Exception as e:
            import traceback
            self.send_json({"error": str(e), "trace": traceback.format_exc()[-500:]}, 500)

    def do_POST(self):
        parsed = urlparse(self.path)
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(content_length)) if content_length else {}
        except:
            body = {}
        
        try:
            if parsed.path == "/index":
                path = body.get("path", "")
                if not path or not os.path.exists(path):
                    return self.send_json({"error": "valid path required"}, 400)
                emb = get_image_embedding(path)
                result = add_image(path, emb)
                self.send_json(result)
            else:
                self.send_json({"error": f"unknown path: {parsed.path}"}, 404)
        except Exception as e:
            self.send_json({"error": str(e)}, 500)

# ─── INDEX TEST IMAGES ────────────────────────────────────────────────────────
def _index_test_images():
    """Index all test images at startup (deduplicated)."""
    test_images = [
        "/tmp/test_dog.jpg",
        "/tmp/test_beach.jpg",
        "/tmp/test_dinner.jpg",
    ]
    browser_images = glob.glob("/data/.openclaw/media/browser/*.png")
    all_images = test_images + browser_images
    
    indexed_count = 0
    unique_count = 0
    dup_count = 0
    
    for path in all_images:
        if os.path.exists(path):
            try:
                emb = get_image_embedding(path)
                result = add_image(path, emb)
                if result.get("duplicate"):
                    dup_count += 1
                    print(f"  [dup skip] {os.path.basename(path)}")
                else:
                    unique_count += 1
                    print(f"  [indexed] {os.path.basename(path)} → {result['id']}")
                    indexed_count += 1
            except Exception as e:
                print(f"  [error] {path}: {e}")
    
    print(f"  → {indexed_count} unique images indexed, {dup_count} duplicates skipped")
    return indexed_count

# ─── MAIN ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=== DaVinci Test Server ===")
    indexed = _index_test_images()
    print(f"\nAPI ready at http://localhost:{PORT}")
    
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), Handler) as server:
        server.serve_forever()
