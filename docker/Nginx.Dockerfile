# Extend the official nginx image
FROM nginx:1.25

# Install vim and clean up apt cache
RUN apt-get update && \
    apt-get install -y vim && \
    rm -rf /var/lib/apt/lists/*

