FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install --no-optional

COPY . ./

RUN npm run build

FROM nginx:stable-alpine

COPY --from=builder /app/build /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/

EXPOSE 3000

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
