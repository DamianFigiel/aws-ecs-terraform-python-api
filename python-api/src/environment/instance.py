import os

env = os.environ.get("PYTHON_ENV", "development")
port = os.environ.get("PORT", 8080)

all_environments = {
    "development": { "port": port, "debug": True, "swagger-url": "/api/swagger" },
    "production": { "port": port, "debug": False, "swagger-url": None  }
}

environment_config = all_environments[env]
