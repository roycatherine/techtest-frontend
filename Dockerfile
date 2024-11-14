# Set the base image
FROM node:lts-alpine

# Set working directory
WORKDIR /var/www

# Copy `package.json` and `package-lock.json`
COPY package*.json ./

# Install project dependencies
RUN npm install

# Copy project files into the docker image
COPY . .

# Expose the port Vite runs on
EXPOSE 3000

# Start the Vite server
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
