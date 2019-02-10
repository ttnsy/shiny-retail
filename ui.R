# header -----------------------------------------------------------------------

# full header
header <- dashboardHeader()

# sidebar ----------------------------------------------------------------------

# full sidebar menu
sidebar <- dashboardSidebar(
  
  # menu list
  sidebarMenu(
    
    # home
    menuItem(
      tabName = "home",
      text = "Home",
      icon = icon("home")
      
    ),
    
    # summary
    menuItem(
      tabName = "summary",
      text = "Summary Statistics",
      icon = icon("chart-bar", "regular")
      
    ),
    
    # forecast
    menuItem(
      tabName = "forecast",
      text = "Sales Forecast",
      icon = icon("chart-line")
      
    ),
    
    # region
    menuItem(
      tabName = "region",
      text = "Regional Analysis",
      icon = icon("globe-americas")
      
    ),
    
    # customer
    menuItem(
      tabName = "customer",
      text = "Customer Profile",
      icon = icon("users")
      
    )
    
  )
  
)

# body -------------------------------------------------------------------------

# full body
body <- dashboardBody(
  
  # full items
  tabItems(
    
    # summary
    tabItem(tabName = "summary",
      
      # row: title
      h1("Historical Statistics", align = "center"),

      # row: opts
      fluidRow(
        
        # col: opts
        column(
          
          # opts
          radioButtons(inputId = "sumHistOptsAgg",
            label = h4("Aggregration:"),
            choices = c(
              "Daily" = "day",
              "Weekly" = "week",
              "Monthly" = "month",
              "Quarterly" = "quarter"
            ),
            selected = "quarter",
            inline = TRUE
          ),
          
          # spacing
          br(),

          # settings
          width = 12,
          align = "center"
          
        )
                
      ),
      
      # row: plot
      fluidRow(
        
        # col: plot
        column(
          
          # plot
          echarts4rOutput(
            outputId = "sumHistPlot",
            height = 350
          ),
          
          # spacing
          br(),
          
          # settings
          width = 12,
          align = "center"
          
        )
        
      ),

      # row: stats
      fluidRow(
        
        # title
        h3(textOutput("sumHistStatsTitle"), align = "center"),
        
        # spacing
        br(),
      
        # col: stats
        column(
      
          # box
          valueBoxOutput("sumHistStats", width = NULL),
      
          # settings
          width = 12,
          align = "center"
      
        )
      
      )
      
    )

  )
    
)

# full ui ----------------------------------------------------------------------

# wrap-up all comps
dashboardPagePlus(
  
  # title
  title = "Retail Analytics Dashboard",
  
  # full page comps
  header = header,
  sidebar = sidebar,
  body = body,
  
  # settings
  enable_preloader = TRUE,
  collapse_sidebar = TRUE
  
)
