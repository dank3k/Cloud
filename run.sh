#!/bin/sh

# Jalankan Nginx di background
nginx -g 'daemon off;' &

# Jalankan Nginx Prometheus Exporter di background
# Exporter akan scrape dari localhost pada endpoint /stub_status
/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://127.0.0.1/stub_status &

# Tunggu hingga salah satu proses di atas selesai (misalnya, jika salah satu crash)
wait -n

# Keluar dengan kode status dari proses yang selesai
exit $?
