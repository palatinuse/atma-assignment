library(plumber)

#* @apiTitle ATMA Implementation Assignment - Endre Palatinus
#* @apiDescription Your task is to (1) implement a (rudimentary) system to analyze this track and trace sample and (2) build a REST API that can ingest data in this format and trigger the analysis on the fly.
#* @apiVersion 1.0


# Libraries used:
library(igraph)
library(ggplot2)
library(plotly)
library(lubridate)
library(magrittr)
library(dplyr)
library(tibble)
library(RColorBrewer)


# Global variables:

events = tribble(~timestamp, ~item, ~location, ~readpoint)
itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint)



#' Insert a new event
#' @post /events
#' @param timestamp Date and time
#' @param item Unique item identifier
#' @param location Location identifier
#' @param readpoint Readpoint identifier
insertEvent = function(req, timestamp = lubridate::now(), item, location, readpoint) {

  events <<- add_row(events,
                     timestamp = ymd_hms(timestamp),
                     item = item,
                     location = location,
                     readpoint = readpoint
  )
}

#' Lookup the events related to a given item
#' @get /items/<id>/events
#' @param id:character the ID of the item
getEvents = function(id) {
  filter(events, item == id)
}

#' Lookup the item flow information of a given item
#' @get /items/<id>/itemflow
#' @param id:character the ID of the item
getItemFlow = function(id) {
  filter(itemFlow, item == id)
}

#' Plot the item flow of a given item. The edge width is relative to the dwell time, and the edge color shows the readpoint.
#' @get /items/<id>/itemflowplot
#' @param id:character the ID of the item
#' @png
getItemFlowPlot = function(id) {
  data = itemFlow %>% filter(item == id)
  itemFlowG = graph.edgelist(as.matrix(data %>% select(source, target)), directed = T)
  itemFlowG = set_edge_attr(graph = itemFlowG, name = "duration", value = data$duration)

  coul = brewer.pal(n_distinct(data$readpoint), "Set1")
  my_color <- coul[as.numeric(as.factor(data$readpoint))]

  plot(itemFlowG, edge.width = log(1 + log(1 + data$duration)), edge.color = my_color)
  legend("bottomleft", legend=levels(as.factor(data$readpoint)), col = coul , bty = "n",
         pch = 20 , pt.cex = 3, cex = 1.0, text.col = coul, horiz = FALSE, inset = c(0.0, 0.0))

}

#' Show the transition probabilities for a given location
#' @get /locations/<id>/prob
#' @param id:character the ID of the location
#' @serializer htmlwidget
getTransitionProbs = function(id) {
  incoming = itemFlow %>%
    filter(target == id) %>%
    group_by(source) %>%
    count() %>%
    ungroup() %>%
    mutate(probability = n / sum(n))

  outgoing = itemFlow %>%
    filter(source == id) %>%
    group_by(target) %>%
    count() %>%
    ungroup() %>%
    mutate(probability = n / sum(n))

  probs = bind_rows(incoming %>% rename(location = source) %>% mutate(direction = "incoming"),
                    outgoing %>% rename(location = target) %>% mutate(direction = "outgoing"))
  probs$direction %<>% as.factor()
  probs$location %<>% as.factor()

  if (nrow(probs) == 0) {
    return(NULL)
  }

  g = ggplot(probs, aes(x = location, y = probability, fill = direction)) +
    geom_bar(stat = 'identity') +
    facet_wrap(~direction) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    labs(title = paste0("Transition probabilites for location ", id))

  ggplotly(g)
}


### Plotting functions ###

#' Plot location heat-map.
#' @get /locations
#' @serializer htmlwidget
plotLocationHeatMap = function() {
  itemFlowStats = itemFlow %>%
    group_by(source, target) %>%
    summarise(n = n(), n_readpoints = n_distinct(readpoint), n_items = n_distinct(item))

  g = ggplot(data = itemFlowStats, aes(x = source, y = target, fill = n)) +
    geom_tile() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))
  ggplotly(g)
}


### Load sample data ###

#' Function for loading the sample data.
#' @get /init
loadSampleData = function() {
  events = read.csv2(header = F, stringsAsFactors = F, numerals = "no.loss",
                     file = "data/readEvents.csv")

  names(events) = c("timestamp", "item", "process", "location", "run", "readpoint")
  events$timestamp %<>% ymd_hms() # NOTE: loosing millisecond precision here
  events$timestamp %<>% as.numeric()
  events$location %<>% as.factor()
  events$readpoint %<>% as.factor()
  events$item %<>% as.factor()

  # Remove process and run from this analysis (as denoted in the assignments)
  events %<>% select(-process, -run)

  events <<- events

  sprintf("[+] Successfully loaded %d rows from the sample dataset.", nrow(events))
}

#' Function for loading the sample data and the pre-calculated item flow as well.
#' @get /initall
loadAll = function() {
  loadSampleData()
  itemFlow <<- readRDS(file = "data/itemFlow.rds")
}

### Trigger the analysis ###

#' Calculate item flow from the events log.
#' @get /calculate/itemflow
function() {

  itemFlow <<- calculateItemFlow(events)
}

#' Function for calculating the event flow of the items.
#' @param events the event log
#' @return the list of transitions for each item
calculateItemFlow = function(events) {

  events %<>% arrange(item, timestamp)

  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint)

  if (nrow(events) <= 1) {
    return(itemFlow)
  }

  for (i in 2:nrow(events)) {
    if (events$item[i - 1] == events$item[i]) {
      itemFlow %<>% add_row(
        item = events$item[i],
        source = events$location[i - 1], target = events$location[i],
        begin = events$timestamp[i - 1], end = events$timestamp[i],
        #duration = difftime(events$timestamp[i], events$timestamp[i - 1], units = "secs"),
        duration = events$timestamp[i] - events$timestamp[i - 1],
        readpoint = events$readpoint[i])
    }
  }

  itemFlow
}
