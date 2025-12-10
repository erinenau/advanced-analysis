library(shiny)
library(magick)
library(randomForest)
library(base64enc)

## ------------------------------------------------------------------
# Function to extract simple features from an image
## ------------------------------------------------------------------
extract_features <- function(img_path) {
  img <- image_read(img_path)
  
  # Resize to standard size for consistency
  img <- image_resize(img, "100x100!")
  
  # Get image data as array
  img_array <- as.integer(image_data(img, channels = "rgb"))
  
  # Extract features: mean RGB values, standard deviation
  features <- c(
    mean_r = mean(img_array[1,,]),
    mean_g = mean(img_array[2,,]),
    mean_b = mean(img_array[3,,]),
    sd_r = sd(img_array[1,,]),
    sd_g = sd(img_array[2,,]),
    sd_b = sd(img_array[3,,])
  )
  
  return(features)
}

## ------------------------------------------------------------------
## Tiny gradient descent demo for logistic regression
## ------------------------------------------------------------------  

# Vehicle dataset
vehicle_X <- matrix(c(
  4.5, 3.0,  # heavy, thick armor  -> armored      
  5.0, 3.5,                                      
  4.0, 2.8,                                      
  1.0, 0.5,  # light, thin armor   -> non-armored  
  1.5, 0.7,                                      
  2.0, 0.9                                      
), ncol = 2, byrow = TRUE)                      

vehicle_y <- c(1, 1, 1, 0, 0, 0)  # 1 = armored, 0 = non-armored          

# basic gradient descent for logistic regression                 
gradient_descent_logistic <- function(X, y, lr = 0.1, n_iter = 60) {  
  n <- nrow(X)                                                        
  d <- ncol(X)                                                      
  w <- rep(0, d)                                                    
  b <- 0                                                              
  
  loss_history <- numeric(n_iter)                                     
  
  for (i in 1:n_iter) {                                               
    z <- X %*% w + b                                                  
    p <- 1 / (1 + exp(-z))  # sigmoid                                 
    
    # Binary cross-entropy loss                                       
    loss <- -mean(y * log(p + 1e-8) + (1 - y) * log(1 - p + 1e-8))    
    loss_history[i] <- loss                                           
    
    # Gradients                                                       
    grad_w <- t(X) %*% (p - y) / n                                    
    grad_b <- mean(p - y)                                             
    
    # Parameter update                                                
    w <- w - lr * as.vector(grad_w)                                   
    b <- b - lr * grad_b                                              
  }                                                                   
  
  list(loss = loss_history, w = w, b = b)                             
}                                                                     

gd_results <- gradient_descent_logistic(vehicle_X, vehicle_y)                 


# UI
ui <- fluidPage(
  titlePanel("🚚 Armored vs Non-Armored Vehicle Classifier"),  
  
  sidebarLayout(
    sidebarPanel(
      h3("Step 1: Upload Training Images"),
      fileInput("armored_images",               
                "Upload Armored Vehicle Images (JPG/PNG - select multiple images to upload more than one file)",
                multiple = TRUE, 
                accept = c("image/*", ".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG")),
      fileInput("nonarmored_images",            
                "Upload Non-Armored Vehicle Images (JPG/PNG)",  
                multiple = TRUE, 
                accept = c("image/*", ".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG")),
      hr(),
      actionButton("train_btn", "Train Model", class = "btn-primary"),
      hr(),
      h3("Step 2: Test Your Model"),
      fileInput("test_image", "Upload Test Image", 
                accept = c("image/*", ".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG")),
      width = 3
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Training Data",
                 h4("Armored Vehicle Training Images"),  
                 uiOutput("armored_images_display"),     
                 h4("Non-Armored Vehicle Training Images"),  
                 uiOutput("nonarmored_images_display")       
        ),
        tabPanel("Model Status",
                 h4("Training Status"),
                 verbatimTextOutput("model_status"),
                 verbatimTextOutput("training_info")
        ),
        tabPanel("Prediction",
                 h4("Test Image"),
                 imageOutput("test_image_display", height = "300px"),
                 h3("Prediction Result:"),
                 verbatimTextOutput("prediction_result"),
                 plotOutput("prediction_prob", height = "200px"),
                 br(),
                 h4("Understanding This Prediction"),
                 p(strong("Model Accuracy (on the Model Status page):"),
                   "This measures how well the classifier performs overall on the training dataset using out-of-bag evaluation."),
                 p(strong("Prediction Probability (above):"),
                   "This measures how confident the model is for this single test image."),
                 p("These two values are different because one reflects global model performance while the other reflects confidence in one specific classification."),
                 br(),
                 p(strong("Why model accuracy changes between runs:"), 
                   "The random forest is retrained each time with randomness in sampling and feature selection. With small datasets, OOB accuracy naturally fluctuates."),
                 p(strong("Why prediction confidence varies:"), 
                   "Some images are harder for the model to classify (low confidence), while clear images produce high confidence.")
                   
        ),
        tabPanel("Gradient Descent Demo",   
                 h4("Gradient Descent and Classification"),  
                 p("To understand how gradient descent trains a classifier, we will take a closer 
                   look at what gradient descent means and how it applies to a training model.
                   In many classifiers (like logistic regression and neural networks), 
                   we choose parameters (weights and biases) that separate two classes 
                   (here: armored vs non-armored). The weights represent our slope, or rate of change of the function,
                   and the biases are the intercepts. The model adjusts both of these values as iterations 
                   are preformed, with the goal to minimize the loss (which tells us how badly the prediction is and where it needs to be
                   corrected to move closer to a minimal loss). Once we have defined the model (with weights and biases) and identified an appropriate loss function, a learning rate is chosen (this gives a learning curve for the model). 
                   Gradient descent is an optimization 
                   algorithm that:"),                               
                 tags$ol(                                           
                   tags$li("Starts with an initial guess for the weights and biases."),   
                   tags$li("Computes the loss, which indicates how poorly the classifier is preforming."),
                   tags$li("Calculates the gradient, which points in the direction of *increasing* loss."), 
                   tags$li("Gradient descent updates the weights and biases in the *opposite* direction to reduce the loss."),      
                   tags$li("Iterations repeat until the loss converges at a minimum value, or until the loss is acceptably small.")                         
                 ),                                                   
                 p("Below we will look at a small example (not using your images) where a logistic 
                   regression classifier is trained by gradient descent on two simple features. 
                   The loss should decrease over iterations as the classifier improves."),  
                 plotOutput("gd_loss_plot", height = "250px"),      
                 verbatimTextOutput("gd_equation")                    
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values to store data
  values <- reactiveValues(
    model = NULL,
    trained = FALSE,
    armored_count = 0,       
    nonarmored_count = 0    
  )
  
  # Display uploaded armored images
  output$armored_images_display <- renderUI({   
    if (is.null(input$armored_images)) {        
      return(p("No armored vehicle images uploaded yet"))  
    }
    values$armored_count <- nrow(input$armored_images)     
    
    # Create image tags using base64 encoding for reliability
    img_tags <- lapply(1:min(3, nrow(input$armored_images)), function(i) {  
      img_file <- input$armored_images$datapath[i]                          
      img <- image_read(img_file)
      img <- image_resize(img, "150x150")
      
      # Convert to base64
      tmp <- tempfile(fileext = ".png")
      image_write(img, tmp, format = "png")
      img_base64 <- base64enc::base64encode(tmp)
      unlink(tmp)
      
      tags$img(src = paste0("data:image/png;base64,", img_base64), 
               height = "150px", style = "margin: 5px; border: 2px solid #ddd;")
    })
    
    tagList(
      p(strong(paste("✓ Uploaded", nrow(input$armored_images), "armored vehicle images"))),  
      div(style = "display: flex; flex-wrap: wrap;", img_tags)
    )
  })
  
  # Display uploaded non-armored images
  output$nonarmored_images_display <- renderUI({  
    if (is.null(input$nonarmored_images)) {      
      return(p("No non-armored vehicle images uploaded yet"))  
    }
    values$nonarmored_count <- nrow(input$nonarmored_images)  
    
    # Create image tags using base64 encoding for reliability
    img_tags <- lapply(1:min(3, nrow(input$nonarmored_images)), function(i) {  
      img_file <- input$nonarmored_images$datapath[i]                          
      img <- image_read(img_file)
      img <- image_resize(img, "150x150")
      
      # Convert to base64
      tmp <- tempfile(fileext = ".png")
      image_write(img, tmp, format = "png")
      img_base64 <- base64enc::base64encode(tmp)
      unlink(tmp)
      
      tags$img(src = paste0("data:image/png;base64,", img_base64), 
               height = "150px", style = "margin: 5px; border: 2px solid #ddd;")
    })
    
    tagList(
      p(strong(paste("✓ Uploaded", nrow(input$nonarmored_images), "non-armored vehicle images"))),  
      div(style = "display: flex; flex-wrap: wrap;", img_tags)
    )
  })
  
  # Train the model
  observeEvent  # Train the model
  observeEvent(input$train_btn, {
    # If you want built-in images to be enough, comment out or delete this line:
    # req(input$armored_images, input$nonarmored_images)  
    
    output$model_status <- renderText("Training model... Please wait.")
    
    tryCatch({
      # built-in images
      armored_builtin    <- list.files("www/armored",    full.names = TRUE)
      nonarmored_builtin <- list.files("www/nonarmored", full.names = TRUE)
      
      # Combine built-in + uploaded images
      armored_paths <- c(
        armored_builtin,
        if (!is.null(input$armored_images)) input$armored_images$datapath else character(0)
      )
      
      nonarmored_paths <- c(
        nonarmored_builtin,
        if (!is.null(input$nonarmored_images)) input$nonarmored_images$datapath else character(0)
      )
      
      # Optional: safety check
      if (length(armored_paths) == 0 || length(nonarmored_paths) == 0) {
        stop("No training images found in armored or non-armored sets.")
      }
      
      # Extract features from all images
      armored_features    <- t(sapply(armored_paths,    extract_features))
      nonarmored_features <- t(sapply(nonarmored_paths, extract_features))
      
      # Create labels
      armored_labels    <- rep("Armored",     nrow(armored_features))
      nonarmored_labels <- rep("Non-Armored", nrow(nonarmored_features))
      
      # Combine into training dataset
      train_data <- data.frame(
        rbind(armored_features, nonarmored_features),
        label = factor(c(armored_labels, nonarmored_labels))
      )
      
      # Train random forest model
      values$model   <- randomForest(label ~ ., data = train_data, ntree = 100)
      values$trained <- TRUE
      
      output$model_status <- renderText("✓ Model trained successfully!")
      output$training_info <- renderPrint({
        cat("Training Summary:\n")
        cat("- Armored images:     ", nrow(armored_features),    "\n")
        cat("- Non-Armored images: ", nrow(nonarmored_features), "\n")
        cat("- Total training samples:", nrow(train_data), "\n")
        cat("\nModel Accuracy (Out-of-Bag):", 
            round((1 - values$model$err.rate[100, "OOB"]) * 100, 2), "%\n")
      })
      
    }, error = function(e) {
      output$model_status <- renderText(paste("Error training model:", e$message))
    })
  })
  
  # Display test image
  output$test_image_display <- renderImage({
    req(input$test_image)
    
    # Determine content type from file extension
    ext <- tools::file_ext(input$test_image$name)
    content_type <- switch(tolower(ext),
                           "jpg" = "image/jpeg",
                           "jpeg" = "image/jpeg",
                           "png" = "image/png",
                           "image/jpeg")
    
    list(src = input$test_image$datapath,
         contentType = content_type,
         height = 300)
  }, deleteFile = FALSE)
  
  # Make prediction
  observe({
    req(input$test_image, values$trained)
    
    tryCatch({
      # Extract features from test image
      test_features <- extract_features(input$test_image$datapath)
      test_df <- data.frame(t(test_features))
      
      # Make prediction
      prediction <- predict(values$model, test_df, type = "prob")
      predicted_class <- predict(values$model, test_df)
      
      # Display result
      output$prediction_result <- renderText({
        icon <- ifelse(predicted_class == "Armored", "🛡️", "🚗")  
        confidence <- max(prediction) * 100
        paste0("\n", icon, " Classified as: ", predicted_class, "\n",
               "Confidence: ", round(confidence, 1), "%\n")
      })
      
      # Plot probabilities
      output$prediction_prob <- renderPlot({
        barplot(as.numeric(prediction), 
                names.arg = c("Armored", "Non-Armored"),  
                col = c("#FF6B6B", "#4ECDC4"),
                ylim = c(0, 1),
                main = "Prediction Probabilities",
                ylab = "Probability",
                las = 1)
        abline(h = 0.5, lty = 2, col = "gray")
      })
      
    }, error = function(e) {
      output$prediction_result <- renderText(paste("Error making prediction:", e$message))
    })
  })
  
  ## ------------------------------
  ## Gradient Descent Demo Outputs
  ## ------------------------------  
  
  output$gd_loss_plot <- renderPlot({                      
    plot(seq_along(gd_results$loss), gd_results$loss,     
         type = "b",                                      
         xlab = "Iteration",                              
         ylab = "Loss (binary cross-entropy)",            
         main = "Gradient Descent Training Loss (Vehicle Logistic Classifier)")  
  })                                                       
  
  output$gd_equation <- renderText({                       
    paste0(                                               
      "Final logistic classifier (vehicle example):\n",   
      "σ(",                                                
      round(gd_results$w[1], 3), " * x1 + ",               
      round(gd_results$w[2], 3), " * x2 + ",               
      round(gd_results$b, 3), ")\n",                      
      "where σ(z) = 1 / (1 + e^(−z)) and x1, x2 are simple features." 
    )                                                      
  })                                                       
}

# Run the app
shinyApp(ui = ui, server = server)
