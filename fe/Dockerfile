FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . ./

ARG REACT_APP_COGNITO_UI
ARG REACT_APP_COGNITO_LOGOUT

ENV REACT_APP_COGNITO_UI=$REACT_APP_COGNITO_UI
ENV REACT_APP_COGNITO_LOGOUT=$REACT_APP_COGNITO_LOGOUT

RUN npm run build

FROM nginx:stable-alpine

COPY --from=builder /app/dist /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/

EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
