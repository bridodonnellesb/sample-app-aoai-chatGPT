FROM node:20-alpine AS frontend
RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app
COPY ./frontend/package*.json ./
USER node
RUN npm ci
COPY --chown=node:node ./frontend/ ./
COPY --chown=node:node ./static/ ./
WORKDIR /home/node/app/frontend
RUN npm run build

# Use Debian slim image instead of Alpine
FROM python:3.11-slim

# Install LibreOffice and other dependencies
RUN apt-get update && apt-get install -y \
    libreoffice \
    libreoffice-writer \
    fonts-opensymbol \
    hyphen-fr \
    hyphen-de \
    hyphen-en-us \
    hyphen-it \
    hyphen-ru \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    fonts-droid-fallback \
    fonts-dustin \
    fonts-f500 \
    fonts-fanwood \
    fonts-freefont-ttf \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Install other required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libffi-dev \
    libssl-dev \
    curl \
    libpq-dev \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt \
    && rm -rf /root/.cache

COPY . /usr/src/app/
COPY --from=frontend /home/node/app/static /usr/src/app/static/
WORKDIR /usr/src/app
EXPOSE 80

CMD ["gunicorn", "-b", "0.0.0.0:80", "app:app"]