# ATMA Assignment - Endre Palatinus

This is a project I have created as part of the interview process at ATMA.

# Getting started

- Clone this git repository. 
- Build the docker container: ```docker build . --rm -t atma/assignment```
- Run the docker container: ```sudo docker run -p 8000:8000 atma/assignment```
- Visit the following URL to explore the API: ```localhost:8000/__swagger__```

# Implementation details

- RESTful API implemented in R
- Docker container for deploying the API and exploring it using swagger
- persistence layer: in-memory global dataframes inside the R process serving as the API backend
