# server start -----------------------------------------------------------------

function(input, output, session) {

# summary ----------------------------------------------------------------------

  # trend: get data
  sumHistRv <- reactive({
    
    # get opts
    optsAgg <- input$sumHistOptsAgg
    optsSeries <- str_to_lower(input$sumHistOptsSeries)
    
    # data wrangling
    trend %>%
      select_("datetime", "country", optsSeries) %>%
      mutate(datetime = case_when(
        optsAgg == "day" ~ floor_date(datetime, optsAgg) %>% as.Date(),
        TRUE ~ (ceiling_date(datetime, optsAgg) %>% as.Date()) - days(1),
      )) %>%
      group_by(datetime, country) %>%
      summarise_at(vars(-datetime, -country), funs(sum(.))) %>%
      ungroup() %>%
      gather(key, value, -datetime, -country) %>%
      mutate(
        country = str_to_title(country),
        key = str_to_title(key),
        value = ifelse(value == 0, NA, value)
      ) %>%
      drop_na()
    
  })

  # trend: get data
  sumHistAggRv <- reactive({
    
    # get opts
    optsAgg <- input$sumHistOptsAgg
    optsSeries <- str_to_lower(input$sumHistOptsSeries)
    
    # data wrangling
    trend_agg %>%
      select_("datetime", optsSeries) %>%
      group_by(datetime = case_when(
        optsAgg == "day" ~ floor_date(datetime, optsAgg) %>% as.Date(),
        TRUE ~ (ceiling_date(datetime, optsAgg) %>% as.Date()) - days(1),
      )) %>%
      summarise_at(vars(-datetime), funs(sum(.))) %>%
      ungroup() %>%
      gather(key, value, -datetime) %>%
      mutate(
        key = str_to_title(key),
        value = ifelse(value == 0, NA, value)
      ) %>%
      drop_na()
    
  })

  # trend: plot
  output$sumHistPlot <- renderEcharts4r({
    
    # data
    data <- sumHistAggRv() %>%
      mutate(datetime = format(datetime, "%b %e, %y"))
    
    # chart
    data %>%
      group_by(key) %>%
      e_chart(datetime) %>%
      e_line(value) %>%
      e_legend(show = FALSE) %>%
      e_tooltip("axis") %>%
      e_datazoom(type = "inside") %>%
      e_toolbox(show = FALSE) %>%
      e_theme("westeros")
    
  })
  
  # trend: plot events
  sumHistDateSelected <- reactive({
    
    # available dates
    availDates <- sumHistAggRv() %>% pull(datetime)
    
    # trend: date selected
    if (is.null(input$sumHistPlot_clicked_row))
      
      selectedDate <- last(availDates)
    
    else
    
      selectedDate <- availDates[input$sumHistPlot_clicked_row]
      
    # handle data change
    if (!(selectedDate %in% availDates)) selectedDate <- last(availDates)
    
    # return selected date
    selectedDate
    
  })
  
  # trend: selected statistics title
  output$sumHistStatsTitle <- renderText({
    
    selectedDate <- format(sumHistDateSelected(), "%B %e, %Y")
    
    paste("Summary Statistics as of", selectedDate)
    
  })
  
  # trend: plot
  output$sumHistStatsShare <- renderEcharts4r({
  
    # data
    data <- sumHistRv() %>%
      filter(datetime == sumHistDateSelected())
  
    # chart
    data %>%
      group_by(key) %>%
      e_chart(country) %>%
      e_bar(value) %>%
      e_flip_coords() %>%
      e_legend(show = FALSE) %>%
      e_tooltip("axis") %>%
      e_toolbox(show = FALSE) %>%
      e_theme("westeros")
  
  })
  
  # trend: selected statistics
  output$sumHistStatsCum <- renderValueBox({
  
    # data
    data <- sumHistAggRv()
  
    # opts
    optsAgg <- input$sumHistOptsAgg
    optsSeries <- input$sumHistOptsSeries
  
    # selected date
    dateNow <- sumHistDateSelected()
  
    # handle choosed data
    if (dateNow == first(data$datetime)) {
  
      obj <- valueBox(
        value = "-",
        subtitle = "Choose more recent date",
        color = "yellow",
        icon = icon("exclamation-circle")
      )
  
      return(obj)
  
    }
  
    # cumulative sum
    cum <- sumHistAggRv() %>%
      filter(
        year(datetime) == year(dateNow),
        datetime <= dateNow
      ) %>%
      pull(value) %>%
      sum()
    
    # value
    value <- case_when(
      (cum / 1e8) >= 1 ~ paste(round(cum / 1e9, 2), "B"),
      (cum / 1e5) >= 1 ~ paste(round(cum / 1e6, 2), "M"),
      (cum / 1e2) >= 1 ~ paste(round(cum / 1e3, 2), "K"),
      TRUE ~ paste(cum)
    )
    
    # handle currency
    value <- case_when(
      optsSeries == "Amount" ~ paste("$", value),
      TRUE ~ paste(value)
    )
  
    # render box
    valueBox(
      value = value,
      subtitle = "Cumulative Sum",
      color = "light-blue"
    )
  
  })
  # trend: selected statistics
  output$sumHistStatsGrowth <- renderValueBox({
  
    # data
    data <- sumHistAggRv()
  
    # opts
    optsAgg <- input$sumHistOptsAgg
  
    # selected date
    dateNow <- sumHistDateSelected()
  
    # handle choosed data
    if (dateNow == first(data$datetime)) {
  
      obj <- valueBox(
        value = "-",
        subtitle = "Choose more recent date",
        color = "yellow",
        icon = icon("exclamation-circle")
      )
  
      return(obj)
  
    }
  
    # previous date
    datePrev <- data$datetime[which(data$datetime == dateNow) - 1]
  
    # values
    vals <- sumHistAggRv() %>%
      filter(datetime %in% c(datePrev, dateNow)) %>%
      pull(value)
  
    # growth
    growth <- ((vals[2] - vals[1]) / vals[1]) * 100
  
    # value
    value <- case_when(
      growth > 0 ~ paste(round(growth, 2), "%"),
      growth < 0 ~ paste(round(growth, 2), "%"),
      TRUE ~ "Invalid value"
    )
  
    # subtitle
    subtitle <- case_when(
      growth > 0 ~ paste0(str_to_title(optsAgg), "-to-", str_to_title(optsAgg)),
      growth < 0 ~ paste0(str_to_title(optsAgg), "-to-", str_to_title(optsAgg)),
      TRUE ~ "Can't calculate selected date"
    )
  
    # color
    color <- case_when(
      growth > 0 ~ "green",
      growth < 0 ~ "red",
      TRUE ~ "yellow"
    )
  
    # icon
    boxIcon <- case_when(
      growth > 0 ~ "arrow-up",
      growth < 0 ~ "arrow-down",
      TRUE ~ "exclamation-circle"
    )
  
    # render box
    valueBox(
      value = value,
      subtitle = subtitle,
      color = color,
      icon = icon(boxIcon)
    )
  
  })

# region -----------------------------------------------------------------------

  #

# server end -------------------------------------------------------------------

}
