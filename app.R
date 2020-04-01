library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)


covid_df <- read.csv(here::here("Data", "covid_df"),
                          stringsAsFactors = FALSE)

# User interface ------------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Kethavi hatralekos idosor dekompozicio"),
  sidebarLayout(
    sidebarPanel(
      h2("Definicio:"),
      p("Ket havi hatralekosnak tekintjuk azt a szerzodest, ahol 2 honapja nem erkezett be a gyakorisag szerinti dij"),
      varSelectInput("variable1", "Dimenzio", covid_df[c(2,4:8)])
    ),
    mainPanel(
      plotOutput("trends")
    )
  )
)


# Server ------------------------------------------------------------------------
server <- function(input, output) {
  
  filtered <- reactive({
    covid_df %>%
      group_by(IDOSZAK, !!input$variable1, HAT_2_HO) %>% 
      summarize(DARAB = sum(DARAB)) %>% 
      ungroup() %>% 
      group_by(IDOSZAK, !!input$variable1) %>% 
      mutate(TOTAL = sum(DARAB)) %>% 
      mutate(HATRALEKOS_ARANY = DARAB / TOTAL) %>% 
      ungroup() %>% 
      filter(HAT_2_HO == 'I') %>% 
      mutate(IDOSZAK = as.Date(IDOSZAK)) %>% 
      select(IDOSZAK, !!input$variable1, HATRALEKOS_ARANY) %>% 
      arrange(!!input$variable1, IDOSZAK)
  })
  
  
  output$trends <- renderPlot({
    
    p <- ggplot(filtered(), aes(IDOSZAK, HATRALEKOS_ARANY)) +
      geom_point() +
      geom_smooth() +
      facet_wrap(names(filtered())[2], ncol = 3, scales = "free")
    
    print(p)
    
  })

}

shinyApp(ui, server)
