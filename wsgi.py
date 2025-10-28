from app import app

# IIS için WSGI application
application = app

if __name__ == "__main__":
    app.run()
