# server start -----------------------------------------------------------------

function(input, output, session) {

# summary ----------------------------------------------------------------------

  # initiate reactives
  sumRvs <- reactiveValues()

  # trend: get data
  sumHistAggRv <- reactive({
    
    # get opts
    opts <- input$sumHistOptsAgg
    
    # data wrangling
    trend_agg %>%
      select_("datetime", "quantity") %>%
      group_by(
        datetime = case_when(
          opts == "day" ~ floor_date(datetime, opts) %>% as.Date(),
          TRUE ~ (ceiling_date(datetime, opts) %>% as.Date()) - days(1),
        )
      ) %>%
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
      mutate(value = value / 1000)
    
    # chart
    data %>%
      group_by(key) %>%
      e_chart(datetime) %>%
      e_line(value) %>%
      e_format_y_axis(suffix = "K") %>%
      e_legend(show = FALSE) %>%
      e_tooltip("axis") %>%
      e_datazoom(type = "inside") %>%
      e_toolbox(show = FALSE) %>%
      e_theme("westeros")
    
  })
  
  # trend: plot events
  observe({
  
    # trend: date selected
    if (is.null(input$sumHistPlot_clicked_row))
      
      sumRvs$histDateSelected <- nrow(sumHistAggRv())
    
    else
    
      sumRvs$histDateSelected <- input$sumHistPlot_clicked_row
  
  })
  
  # trend: plot update
  observeEvent(sumHistAggRv(), {
  
    # trend: date selected
    sumRvs$histDateSelected <- nrow(sumHistAggRv())
  
  })
  
  # trend: selected statistics title
  output$sumHistStatsTitle <- renderText({
    
    availDates <- sumHistAggRv() %>% pull(datetime)
    
    selectedDate <- format(availDates[sumRvs$histDateSelected], "%b %e, %Y")
    
    paste("Statistics as of", selectedDate)
    
  })
  
  # trend: selected statistics
  output$sumHistStats <- renderValueBox({
  
    # data
    data <- sumHistAggRv()
  
    # opts
    opts <- input$sumHistOptsAgg
  
    # available dates
    availDates <- data$datetime
  
    # selected date
    dateNow <- availDates[sumRvs$histDateSelected]
  
    # handle change in data
    if (!(dateNow %in% data$datetime)) {
  
      obj <- valueBox(
        value = "-",
        subtitle = "No date selected",
        color = "light-blue",
        icon = icon("exclamation-circle")
      )
  
      return(obj)
  
    }
  
    # handle choosed data
    if (dateNow == min(data$datetime)) {
  
      obj <- valueBox(
        value = "-",
        subtitle = "Please choose more recent date",
        color = "yellow",
        icon = icon("exclamation-circle")
      )
  
      return(obj)
  
    }
  
    # previous date
    datePrev <- availDates[sumRvs$histDateSelected - 1]
  
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
    boxSubtitle <- case_when(
      growth > 0 ~ paste0(str_to_title(opts), "-to-", str_to_title(opts)),
      growth < 0 ~ paste0(str_to_title(opts), "-to-", str_to_title(opts)),
      TRUE ~ "Can't calculate selected date"
    )
  
    # color
    boxColor <- case_when(
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
      subtitle = boxSubtitle,
      color = boxColor,
      icon = icon(boxIcon)
    )
  
  })

# region -----------------------------------------------------------------------

  #

# server end -------------------------------------------------------------------

}
