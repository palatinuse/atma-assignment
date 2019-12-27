library(testthat)
library(tibble)
library(lubridate)

test_that("empty item flow", {
  events = tribble(~timestamp, ~item, ~location, ~readpoint)
  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint)

  expect_equal(itemFlow, calculateItemFlow(events))
})

test_that("a single event only", {
  events = tribble(~timestamp, ~item, ~location, ~readpoint,
                   lubridate::now(), "12345", "Loc100", "R001")
  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint)

  expect_equal(itemFlow, calculateItemFlow(events))
})

test_that("two events of the same item", {
  timestamp = lubridate::now()

  events = tribble(~timestamp, ~item, ~location, ~readpoint,
                   timestamp, "12345", "Loc100", "R001",
                   timestamp + minutes(1), "12345", "Loc200", "R001")
  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint,
                     "12345", "Loc100", "Loc200", as.numeric(timestamp), as.numeric(timestamp + minutes(1)), 60, "R001")

  expect_equal(itemFlow, calculateItemFlow(events))
})

test_that("three events of the same item", {
  t1 = lubridate::now()
  t2 = t1 + minutes(1)
  t3 = t1 + minutes(2)

  events = tribble(~timestamp, ~item, ~location, ~readpoint,
                   t1, "12345", "Loc100", "R001",
                   t2, "12345", "Loc200", "R001",
                   t3, "12345", "Loc300", "R001")
  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint,
                     "12345", "Loc100", "Loc200", as.numeric(t1), as.numeric(t2), 60, "R001",
                     "12345", "Loc200", "Loc300", as.numeric(t2), as.numeric(t3), 60, "R001")

  expect_equal(itemFlow, calculateItemFlow(events))
})

test_that("three events of the same item - unsorted", {
  t1 = lubridate::now()
  t2 = t1 + minutes(1)
  t3 = t1 + minutes(2)

  events = tribble(~timestamp, ~item, ~location, ~readpoint,
                   t1, "12345", "Loc100", "R001",
                   t3, "12345", "Loc300", "R001",
                   t2, "12345", "Loc200", "R001")
  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint,
                     "12345", "Loc100", "Loc200", as.numeric(t1), as.numeric(t2), 60, "R001",
                     "12345", "Loc200", "Loc300", as.numeric(t2), as.numeric(t3), 60, "R001")

  expect_equal(itemFlow, calculateItemFlow(events))
})

test_that("two events each for two different items", {
  t1 = lubridate::now()
  t2 = t1 + minutes(1)

  events = tribble(~timestamp, ~item, ~location, ~readpoint,
                   t1, "12345", "Loc100", "R001",
                   t2, "12345", "Loc200", "R001",
                   t1, "42", "Loc200", "R002",
                   t2, "42", "Loc100", "R002")
  itemFlow = tribble(~item, ~source, ~target, ~begin, ~end, ~duration, ~readpoint,
                     "12345", "Loc100", "Loc200", as.numeric(t1), as.numeric(t2), 60, "R001",
                     "42", "Loc200", "Loc100", as.numeric(t1), as.numeric(t2), 60, "R002")

  expect_equal(itemFlow, calculateItemFlow(events))
})
