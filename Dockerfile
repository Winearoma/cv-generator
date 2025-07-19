FROM ubuntu:latest AS base
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
# Create and change to the app directory.
WORKDIR /app

# Copy application files
COPY ./app ./
# Install dependencies and clean cache
RUN apt-get update && apt-get -y upgrade && apt-get -y install jq texlive-latex-base texlive-latex-extra && rm -rf /var/lib/apt/lists/*
# Ensure script is executable
RUN chmod +x build-cv.sh
