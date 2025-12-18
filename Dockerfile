# Dockerfile для arxivThreatIntel с Shiny GUI
FROM rocker/r-ver:4.3.2

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Установка R пакетов
RUN R -e "install.packages(c( \
    'shiny', \
    'bslib', \
    'DT', \
    'dplyr', \
    'ggplot2', \
    'shinycssloaders', \
    'httr2', \
    'xml2', \
    'readr', \
    'stringr', \
    'tibble', \
    'lubridate', \
    'tidyr', \
    'devtools', \
    'testthat' \
    ), repos='https://cloud.r-project.org/')"

# Создание рабочей директории
WORKDIR /app

# Копирование всего проекта
COPY . /app/

# Установка пакета
RUN R CMD INSTALL . --preclean

# Открытие порта для Shiny
EXPOSE 8080

# Команда запуска Shiny приложения
CMD ["R", "-e", "arxivThreatIntel::run_app(host='0.0.0.0', port=8080, launch_browser=FALSE)"]