FROM rocker/tidyverse:4.5.0

WORKDIR /app

# Copy scripts
COPY check-status.R entrypoint.sh /app/

# Make the scripts executable
RUN chmod +x /app/*

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
