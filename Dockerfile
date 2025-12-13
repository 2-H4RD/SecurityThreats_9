FROM rocker/r-ver:4.4.2

ARG QUARTO_VERSION=1.5.57

# System dependencies: build tools, libs for R packages, Quarto install, simple web server
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    python3 \
    make \
    g++ \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff5-dev \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Install Quarto CLI (Deb package)
RUN curl -L -o /tmp/quarto.deb \
      https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb \
 && dpkg -i /tmp/quarto.deb \
 && rm -f /tmp/quarto.deb

WORKDIR /app

# Copy project sources (R package + quarto/)
COPY . /app

# Install pak and dependencies, then install the local package
RUN R -q -e "install.packages('pak', repos='https://cloud.r-project.org')" \
 && R -q -e "pak::pkg_install(c('dplyr','tibble','stringr','lubridate','httr2','xml2','ggplot2','readr'))" \
 && R -q -e "pak::pkg_install(c('DT'), ask = FALSE)" \
 && R CMD INSTALL .

# Render output directory
RUN mkdir -p /srv

EXPOSE 8080

# Render the Quarto dashboard and serve it
CMD ["bash", "-lc", "quarto render quarto/dashboard.qmd --to html --output-dir /srv && python3 -m http.server 8080 --directory /srv"]
