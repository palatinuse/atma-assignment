# Libraries used:
library(igraph)
library(ggplot2)
library(plotly)
library(lubridate)
library(magrittr)
library(dplyr)
library(tibble)

# Global variables:

events = tribble(~timestamp, ~item, ~location, ~readpoint)
itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint)



#' Inserting a new event.
#' @post /events
#' @param timestamp Date and time
#' @param item Unique item identifier
#' @param location Location identifier
#' @param readpoint Readpoint identifier
insertEvent = function(req, timestamp, item, location, readpoint) {

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


### Plotting functions ###

#' Plot location heat-map.
#' @get /locations/plot
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

#' Plot out item flow of a given item
#' @param itemID If provided, filter the data to only this item
#' @get /itemflow/plot
#' @png
plotItemFlow = function(itemID){

  data = itemFlowStats
  # Filter if the species was specified
  if (!missing(itemID)) {
    data = itemFlow %>% filter(item == itemID)
    itemFlowG = graph.edgelist(as.matrix(data %>% select(source, target)), directed = T)
    itemFlowG = set_edge_attr(graph = itemFlowG, name = "duration", value = data$duration)
  } else {
    itemFlowG = graph.edgelist(as.matrix(itemFlowStats %>% select(source, target)), directed = T)
  }

  plot(itemFlowG, edge.width = itemFlow$duration) # layout = layout_as_tree(itemFlowG),
}

#' Plot out item flow of a given item
#' @param itemID If provided, filter the data to only this item
#' @get /itemflow/plot/interactive
#' @serializer htmlwidget
plotItemFlowInteractive = function(itemID){

  data = itemFlowStats
  # Filter if the species was specified
  if (!missing(itemID)) {
    data = itemFlow %>% filter(item == itemID)
    itemFlowG = graph.edgelist(as.matrix(data %>% select(source, target)), directed = T)
    itemFlowG = set_edge_attr(graph = itemFlowG, name = "duration", value = data$duration)
  } else {
    itemFlowG = graph.edgelist(as.matrix(itemFlowStats %>% select(source, target)), directed = T)
  }

  plot(itemFlowG, edge.width = itemFlow$duration) # layout = layout_as_tree(itemFlowG),
}



### Load sample data ###

#' Function for loading the sample data.
#' @get /init
loadSampleData = function() {
  events = read.csv2(header = F, stringsAsFactors = F, numerals = "no.loss",
                     file = "data/readEvents.csv")

  names(events) = c("timestamp", "item", "process", "location", "run", "readpoint")
  events$timestamp %<>% ymd_hms() # NOTE: loosing millisecond precision here
  events$location %<>% as.factor()
  events$readpoint %<>% as.factor()
  events$item %<>% as.factor()

  # Remove process and run from this analysis (as denoted in the assignments)
  events %<>% select(-process, -run)

  events <<- events

  sprintf("[+] Successfully loaded %d rows from the sample dataset.", nrow(events))
}

### Trigger the analysis ###

#' Calculate item flow from the events log.
#' @get /itemflow
calculateItemFlow = function() {

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
        duration = events$timestamp[i] - events$timestamp[i - 1],
        readpoint = events$readpoint[i])
    }
  }

  itemFlow <<- itemFlow

  itemFlow
}
