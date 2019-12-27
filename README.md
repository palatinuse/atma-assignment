# ATMA Assignment - Endre Palatinus

This is a project I have created as part of the interview process at ATMA.

# Getting started

- Clone this git repository. 
- Build the docker container: ```docker build . --rm -t atma/assignment```
- Run the docker container: ```docker run -p 80:8000 atma/assignment```
- Visit the URL printed by docker to explore the API

# Implementation details

- RESTful API implemented in R
- Docker container for deploying the API and exploring it using swagger
- persistence layer: in-memory global dataframes inside the R process serving as the API backend
