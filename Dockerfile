FROM ubuntu:latest AS base
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
# Create and change to the app directory.
WORKDIR /app

# Retrieve application dependencies.

COPY ./app ./
RUN apt update && apt -y upgrade && apt -y install jq texlive-latex-base texlive-latex-extra



# Copy local code to the container image.
#COPY . ./

#FROM gcr.io/distroless/python3

## Copy the binary to the production image from the builder stage.
#COPY --from=builder /app /app

#WORKDIR /app/api

#ENV ENVIRONMENT="production"
#ENV PYTHONUNBUFFERED=1
#ENV PORT="8080"
#ENV GOOGLE_APPLICATION_CREDENTIALS="/app/secret-file.json"
#ENV PYTHONPATH=/app/venv/lib/python3.5/site-packages
#ENV PATH=/app/venv/bin/:$PATH

## Run the web service on container startup.
#CMD ["wsgi.py"]
