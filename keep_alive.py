import time
import requests
import os
import random
from threading import Thread
from flask import Flask, make_response
import logging

# Set logging to minimal
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

app = Flask('')

@app.route('/')
def home():
    response = make_response("Bot Status: Hyper-Active")
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    return response

def run():
    try:
        app.run(host='0.0.0.0', port=5000, debug=False)
    except:
        pass

def self_ping():
    """Hyper-resilient self-ping: Multiple targets and randomized timing to keep Replit active."""
    time.sleep(10) # Initial wait
    while True:
        try:
            # Multi-vector pinging
            targets = ["http://127.0.0.1:5000/"]
            dev_domain = os.getenv('REPLIT_DEV_DOMAIN')
            if dev_domain:
                targets.append(f"https://{dev_domain}/")
            
            for target in targets:
                try:
                    # Random query string to bypass caching
                    requests.get(f"{target}?pulse={random.random()}", timeout=10)
                except:
                    continue
        except:
            pass
        # High frequency interval (45-90s)
        time.sleep(random.randint(45, 90))

def keep_alive():
    t_server = Thread(target=run)
    t_server.daemon = True
    t_server.start()
    
    # Redundant pingers
    for _ in range(3):
        t_ping = Thread(target=self_ping)
        t_ping.daemon = True
        t_ping.start()
