# Dockerfile untuk aplikasi React 17.0.2 menggunakan multi-stage build

# --- Stage 1: Build Aplikasi React ---
FROM node:17-alpine AS builder

# Menentukan direktori kerja di dalam container.
WORKDIR /app

# Menyalin file package.json dan package-lock.json untuk menginstal dependensi.
# Langkah ini dioptimalkan untuk memanfaatkan Docker cache.
COPY package*.json ./

# Menginstal semua dependensi proyek.
RUN npm install

# Menyalin seluruh kode sumber aplikasi ke dalam direktori kerja.
COPY . .

# Membangun (build) aplikasi React untuk mode produksi.
# Hasil build akan disimpan di direktori `build`.
RUN npm run build

# --- Stage 2: Menjalankan (serve) Aplikasi Menggunakan Nginx dan Prometheus Exporter ---
FROM nginx:alpine

# Menambahkan Prometheus Nginx Exporter dari GitHub
RUN apk add --no-cache curl \
    && curl -sL https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz | tar xz \
    && mv nginx-prometheus-exporter /usr/local/bin/

# Menyalin konfigurasi Nginx kustom dan skrip startup.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Menyalin hasil build aplikasi dari stage 'builder' ke direktori Nginx.
COPY --from=builder /app/build /usr/share/nginx/html

# Mengarahkan Nginx untuk mendengarkan di port 80 dan exporter di port 9113.
EXPOSE 80
EXPOSE 9113

# Perintah untuk menjalankan skrip yang memulai Nginx dan Exporter.
CMD ["/run.sh"]
