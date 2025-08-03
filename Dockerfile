# ====================================================================
# Tahap 1: Build Aplikasi React
# Gunakan base image Node.js yang stabil dan sesuai untuk React 17
# ====================================================================
FROM node:16-alpine AS builder

# Set direktori kerja di dalam container
WORKDIR /app

# Salin file package.json dan package-lock.json untuk menginstal dependensi
# Ini mengoptimalkan cache Docker, jadi npm install hanya berjalan jika file ini berubah
COPY package.json ./
COPY package-lock.json ./

# Jalankan npm install
# Jika ada error di sini, kemungkinan besar masalahnya ada di package.json Anda
RUN npm install

# Salin semua file proyek ke direktori kerja
COPY . .

# Jalankan perintah build untuk menghasilkan aset statis
RUN npm run build

# ====================================================================
# Tahap 2: Jalankan Nginx untuk melayani aplikasi
# Gunakan base image Nginx yang ringan untuk produksi
# ====================================================================
FROM nginx:alpine

# Salin file-file build dari tahap 'builder' ke direktori Nginx
# /usr/share/nginx/html adalah direktori default Nginx untuk file web
COPY --from=builder /app/build /usr/share/nginx/html

# Ekspos port 80 untuk lalu lintas HTTP
EXPOSE 80

# Jalankan Nginx saat container dimulai
CMD ["nginx", "-g", "daemon off;"]
