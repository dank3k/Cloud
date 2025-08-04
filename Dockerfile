# ====================================================================
# Tahap 1: Build Aplikasi React
# ====================================================================
FROM node:17-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# ====================================================================
# Tahap 2: Menjalankan Aplikasi Menggunakan Nginx dan Prometheus Exporter
# ====================================================================
FROM nginx:alpine

# Menambahkan Prometheus Nginx Exporter
RUN apk add --no-cache curl \
    && curl -sL https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz | tar xz \
    && mv nginx-prometheus-exporter /usr/local/bin/

# Menyalin file konfigurasi Nginx dan skrip startup.
# Pastikan file-file ini berada di direktori yang sama dengan Dockerfile Anda.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh

# Memberikan izin eksekusi pada skrip startup.
RUN chmod +x /run.sh

# Menyalin hasil build aplikasi dari tahap 'builder' ke direktori Nginx.
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80
EXPOSE 9113

# Perintah untuk menjalankan skrip yang memulai Nginx dan Exporter.
CMD ["/run.sh"]
