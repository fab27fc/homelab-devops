###############################################
# File:
# Dockerfile
#
# Description:
# Builds the Container Platform Node.js
# application image using Docker.
#
# Lab:
# Lab 06 - Docker Fundamentals
###############################################

FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

EXPOSE 8080

CMD ["npm", "start"]