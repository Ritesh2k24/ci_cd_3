from flask import Flask
from prometheus_client import make_wsgi_app, Counter, generate_latest
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app = Flask(__name__)

# Create a Prometheus metric
REQUESTS = Counter('http_requests_total', 'Total HTTP Requests')

@app.route('/')
def hello():
    REQUESTS.inc()
    return "Hello! The Python application is running and auto-scaling."

# Add prometheus wsgi middleware to route /metrics requests
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)