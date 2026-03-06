FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dashboard.html /usr/share/nginx/html/
COPY dashboard.css /usr/share/nginx/html/
COPY dashboard.js /usr/share/nginx/html/
COPY data.js /usr/share/nginx/html/
