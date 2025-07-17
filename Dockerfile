FROM python:3.11-slim

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
# Copy both requirements files
COPY requirements-dev.txt ./

# Install all dependencies
RUN pip install --no-cache-dir -r requirements-dev.txt

# Copy project files
COPY . .

# Collect static files (optional: comment out if not needed)
RUN python manage.py collectstatic --noinput || true

# Start with migrations and Gunicorn
CMD ["sh", "-c", "python manage.py migrate && gunicorn pinry.wsgi:application --bind 0.0.0.0:8000"]
