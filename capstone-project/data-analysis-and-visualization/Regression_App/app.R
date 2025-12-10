library(shiny)

# -----------------------------
# Regression Coefficients
# -----------------------------
b0 <- 12.5
b1 <- 3.1
b2 <- -0.8
b3 <- 0.45

# -----------------------------
# Load Dataset
# -----------------------------
convoy_data <- read.csv("convoy_data_clean.csv")

# -----------------------------
# User Interface
# -----------------------------
ui <- fluidPage(
  titlePanel("Convoy Fuel Consumption Predictor"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Enter Convoy Inputs:"),
      
      numericInput("weight", "Vehicle Weight (tons):", value = 32, min = 0),
      numericInput("speed", "Average Speed (mph):", value = 42, min = 0),
      numericInput("distance", "Distance Traveled (miles):", value = 85, min = 0),
      
      actionButton("go", "Predict Fuel Consumption"),
      
      hr(),
      verbatimTextOutput("dataInfo")
    ),
    
    mainPanel(
      h3("Predicted Fuel Consumption"),
      verbatimTextOutput("prediction"),
      
      hr(),
      h4("Model Equation"),
      verbatimTextOutput("equation")
    )
  )
)

# -----------------------------
# Server Logic
# -----------------------------
server <- function(input, output, session) {
  
  output$dataInfo <- renderPrint({
    cat("Convoy Dataset Loaded\n")
    cat("Total Rows:", nrow(convoy_data), "\n")
    cat("Columns:", paste(names(convoy_data), collapse = ", "), "\n")
  })
  
  output$equation <- renderPrint({
    cat(sprintf("ŷ = %.2f + %.2f·x1 + (%.2f)·x2 + %.2f·x3\n",
                b0, b1, b2, b3))
    cat("x1 = weight_tons\n")
    cat("x2 = speed_mph\n")
    cat("x3 = distance_miles\n")
  })
  
  predicted <- eventReactive(input$go, {
    b0 +
      b1 * input$weight +
      b2 * input$speed +
      b3 * input$distance
  })
  
  output$prediction <- renderPrint({
    req(predicted())
    cat(sprintf("Predicted Fuel Consumption: %.2f gallons", predicted()))
  })
}

shinyApp(ui = ui, server = server)
