# Stage 1: Build stage
FROM composer:2 as build-stage
WORKDIR /app

# Copy the composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the application source code
COPY . .

# Stage 2: Final runtime stage
FROM php:8.0-apache as final-stage
WORKDIR /var/www/html

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql

# Copy the built application from the build stage
COPY --from=build-stage /app .

# Set environment variables (if needed)
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Configure Apache
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Enable Apache modules and rewrite rules
RUN a2enmod rewrite \
    && service apache2 restart

# Expose port 80
EXPOSE 80

# Define the command to start Apache
CMD ["apache2-foreground"]
