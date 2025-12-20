# ===============================
# arxivThreatIntel — Dockerfile
# Base: R 4.3.2 (rocker)
# CRAN mirror: mirror.truenetwork.ru
# ===============================

FROM rocker/r-ver:4.3.2

ENV DEBIAN_FRONTEND=noninteractive
ENV R_LIBS_SITE=/usr/local/lib/R/site-library

# 1) Зафиксировать CRAN-зеркало глобально (для всех install.packages)
RUN echo "options(repos = c(CRAN = 'https://mirror.truenetwork.ru/CRAN/'))" \
    >> /usr/local/lib/R/etc/Rprofile.site

# 2) Системные зависимости + инструменты сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    make \
    git \
    curl \
    ca-certificates \
    pandoc \
    pkg-config \
    libgit2-dev \
    libwebp-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libicu-dev \
    libzstd-dev \
    libbz2-dev \
    liblzma-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
 && rm -rf /var/lib/apt/lists/*


# 3) Проверка, что зеркало действительно применяется
RUN R -q -e "getOption('repos')"

# 4) Установка зависимостей arxivThreatIntel (Imports)
RUN R -q -e "\
  pkgs <- c('dplyr','ggplot2','httr2','lubridate','readr','stringr','tibble','tidyr','xml2'); \
  install.packages(pkgs, dependencies=TRUE); \
  stopifnot(all(pkgs %in% rownames(installed.packages())))"

# 5) Установка зависимостей GUI (Shiny)
RUN R -q -e "\
  pkgs <- c('shiny','bslib','DT','shinycssloaders'); \
  install.packages(pkgs, dependencies=TRUE); \
  stopifnot(all(pkgs %in% rownames(installed.packages())))"

# 6) (опционально) dev/test инструменты — можно убрать, если не нужны
RUN R -q -e "\
  pkgs <- c('testthat','devtools'); \
  install.packages(pkgs, dependencies=TRUE); \
  stopifnot(all(pkgs %in% rownames(installed.packages())))"

# 7) Копирование проекта
WORKDIR /app
COPY . /app/

# 8) Диагностика перед установкой пакета
RUN R -q -e "\
  cat('R_LIBS_SITE =', Sys.getenv('R_LIBS_SITE'), '\n'); \
  cat('Installed packages:', nrow(installed.packages()), '\n')"

# 9) Установка вашего пакета
RUN R CMD INSTALL . --preclean

# 10) Открытие порта
EXPOSE 8080

# 11) Запуск Shiny-приложения
CMD ["R", "-q", "-e", "arxivThreatIntel::run_app(host='0.0.0.0', port=8080, launch_browser=FALSE)"]
