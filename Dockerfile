# 使用官方 PHP 8.1 FPM 镜像作为基础镜像
FROM php:8.1-fpm

# 设置工作目录
WORKDIR /var/www/html

# 安装系统依赖和 PHP 扩展
# 更新包列表并安装必要的系统库
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    libzip-dev \
    libssl-dev \
    libonig-dev \
    # 清理 apt 缓存
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 PHP 扩展
# gd: 图像处理
# zip: 处理 zip 压缩文件
# pdo pdo_mysql: 数据库连接
# bcmath: 高精度数学运算
# openssl: 加密
# sockets: 网络通信 (如果需要)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql \
    && docker-php-ext-install zip \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install sockets \
    && docker-php-ext-install opcache # 推荐安装 opcache 以提高性能

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制 composer.json 和 composer.lock 文件
COPY composer.json composer.lock ./

# 安装项目依赖 (不包括开发依赖，优化镜像大小)
# --no-dev: 不安装 require-dev 中的依赖
# --optimize-autoloader: 优化自动加载性能
# --no-scripts: 不执行 composer.json 中定义的脚本 (如果安装过程不需要)
RUN composer install --no-dev --optimize-autoloader --no-scripts

# 复制项目文件到工作目录
COPY . .

# 更改文件所有权为 www-data 用户和组，这是 FPM 默认运行的用户
RUN chown -R www-data:www-data /var/www/html

# 暴露 9000 端口 (PHP-FPM 默认端口)
EXPOSE 9000

# 默认启动命令
CMD ["php-fpm"]