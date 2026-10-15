# Use minimal Alpine-based PHP image
FROM php:8.3-alpine

# ติดตั้งเฉพาะเครื่องมือที่จำเป็นและเปิดใช้งาน Opcache ที่มีมาในตัว
RUN apk add --no-cache curl \
    && docker-php-ext-enable opcache

# ติดตั้ง Composer จากอิมเมจทางการ
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ตั้งค่า Opcache สำหรับโปรดักชัน
RUN { \
    echo 'opcache.memory_consumption=64'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# กำหนดโฟลเดอร์ทำงานหลัก
WORKDIR /app

# คัดลอกและติดตั้ง dependencies
COPY composer.json ./
RUN COMPOSER_PROCESS_TIMEOUT=600 composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress \
    --prefer-dist

# คัดลอกซอร์สโค้ดทั้งหมด
COPY api/ ./api/
COPY src/ ./src/

# ใช้ตัวแปรพอร์ตแบบไดนามิกที่ Vercel กำหนดให้ (รองรับ Fallback ไปที่ 8080 กรณีรันโลคัล)
CMD sh -c "php -S 0.0.0.0:${PORT:-8080} -t api"
