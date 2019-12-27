FROM trestletech/plumber
MAINTAINER Endre Palatinus <palatinuse@gmail.com>

#RUN apt-get update --allow-releaseinfo-change
RUN apt-get install -y --no-install-recommends \
                r-cran-rlang \
                r-cran-magrittr \
                r-cran-lubridate \
                r-cran-ggplot2 \
                r-cran-dt \
                r-cran-igraph \
                r-cran-dplyr \
                r-cran-tibble \
                r-cran-testthat \
                r-cran-rcolorbrewer \
                pandoc \
                pandoc-citeproc

RUN install2.r --error plotly

RUN mkdir /root/app
COPY R/plumber.R /root/app/plumber.R
COPY data/readEvents.csv /root/app/data/readEvents.csv
COPY data/itemFlow.rds /root/app/data/itemFlow.rds

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(commandArgs()[4]); pr$run(host='0.0.0.0', port=8000, swagger = TRUE)"]
CMD ["/root/app/plumber.R"]
