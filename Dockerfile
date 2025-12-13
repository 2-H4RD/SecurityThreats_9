FROM rocker/r2u:4.4.2

ARG QUARTO_VERSION=1.5.57

# System deps + Quarto
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git python3 \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/quarto.deb \
      https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb \
 && dpkg -i /tmp/quarto.deb \
 && rm -f /tmp/quarto.deb

WORKDIR /app
COPY . /app

# Install R deps as Ubuntu binaries (fast + stable in CI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-cran-dplyr \
    r-cran-tibble \
    r-cran-stringr \
    r-cran-lubridate \
    r-cran-httr2 \
    r-cran-xml2 \
    r-cran-ggplot2 \
    r-cran-readr \
    r-cran-dt \
 && rm -rf /var/lib/apt/lists/*

# Install your local R package
RUN R CMD INSTALL .

RUN mkdir -p /srv
EXPOSE 8080

# Render and serve
CMD ["bash", "-lc", "quarto render quarto/dashboard.qmd --to html --output-dir /srv && python3 -m http.server 8080 --directory /srv"]
