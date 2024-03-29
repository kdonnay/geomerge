plot.geomerge <- function(x,...){
  
  # PLOTS all numeric variables
  
  # RETRIEVE input data (and variable) names
  full.inputs <- names(x$inputData)
  
  # PARSE optional inputs
  # expects only three specific ones, all other are ignored
  all.params <- list(...)
  if ('period' %in% names(x$data)){
    if (!('period' %in% names(all.params))){
      cat('Output data is spatial panel, showing results only for the last period. Use optional argument "period" to select specific time period.\n')
      period <- max(x$data@data$period)
    }else{
      period <- all.params$period
      cat(paste0('Output data is spatial panel, showing variables only for period ',period,', as specified.\n'))
    }
    x$data@data <- x$data@data[x$data@data$period==period,] 
  }
  if ('inputs' %in% names(all.params)){
    if (is.character(all.params$inputs)){
      full.inputs <- all.params$inputs
    }else{
      cat('NOTE: Optional argument "inputs" has to be a sequence of variable names expressed as characters. Ignoring the argument.\n')
    }
  }
  time.lag <- x$parameters$time.lag
  # CHECK input consistency
  if (!('period' %in% names(x$data))){
    time.lag <- FALSE
  }
  if ('time.lag' %in% names(all.params)){
    time.lag <- all.params$time.lag
    if (time.lag & !x$parameters$time.lag){
      cat('NOTE: Optional argument "time.lag = TRUE" is calling for output that was not generated. Ignoring the argument.\n')
      time.lag <- FALSE
    }
  }
  spat.lag <- x$parameters$spat.lag
  if ('spat.lag' %in% names(all.params)){
    spat.lag <- all.params$spat.lag
    if (spat.lag & !x$parameters$spat.lag){
      cat('NOTE: Optional argument "spat.lag = TRUE" is calling for output that was not generated. Ignoring the argument.\n')
      spat.lag <- FALSE
    }
  }
  ncol <- 2
  if ('ncol' %in% names(all.params)){
    if (is.numeric(all.params$ncol)){
      ncol <- all.params$ncol
    }
  }
  
  # SUBSET to exclude all non-numeric inputs and all specified inputs not actually in inputData
  points.inputs <- 1
  num_points <- sum(sapply(1:length(full.inputs),function(y) class(x$inputData[[full.inputs[y]]])=="SpatialPointsDataFrame"))
  if (length(x$parameters$point.agg)==1){
    point.agg <- rep(x$parameters$point.agg,each=num_points)
  }else{
    point.agg <- x$parameters$point.agg
  }
  inputs <- c()
  var.names <- c()
  for (inpt in 1:length(full.inputs)){
    if (full.inputs[inpt] %in% names(x$inputData)){
      # DISTINGUISH by class of input data
      if (is(x$inputData[[inpt]],'SpatialPointsDataFrame')){
        if (is.numeric(x$data@data[,paste0(full.inputs[inpt],'.',point.agg[points.inputs])])){
          inputs <- c(inputs,full.inputs[inpt])
          # GENERATE full set of variables to plot
          var.names <- c(var.names,paste0(full.inputs[inpt],'.',point.agg[points.inputs]))
          if (time.lag & !spat.lag){
            var.names <- c(var.names,paste0(full.inputs[inpt],'.',point.agg[points.inputs],'.t_1'))
          }else if (!time.lag & spat.lag){
            var.names <- c(var.names,paste0(full.inputs[inpt],'.',point.agg[points.inputs],'.1st'))
          }else if (time.lag & spat.lag){
            var.names <- c(var.names,paste0(full.inputs[inpt],'.',point.agg[points.inputs],'.t_1'),paste0(full.inputs[inpt],'.',point.agg[points.inputs],'.1st')) 
          }
        }else{
          cat(paste0('NOTE: Selected input ',full.inputs[inpt],' is not a numeric variable. Ignoring ',full.inputs[inpt],' for plotting results.\n'))
        }
        points.inputs <- points.inputs + 1
      }else if (is(x$inputData[[inpt]],'SpatialPolygonsDataFrame')){
        if (is.numeric(x$data@data[,full.inputs[inpt]])){
          inputs <- c(inputs,full.inputs[inpt])
          # GENERATE full set of variables to plot
          var.names <- c(var.names,full.inputs[inpt])
          if (spat.lag){
            var.names <- c(var.names,paste0(full.inputs[inpt],'.1st'))
          }
        }else{
          cat(paste0('NOTE: Selected input ',full.inputs[inpt],' is not a numeric variable. Ignoring ',full.inputs[inpt],' for plotting results.\n'))
        }
      }else if (is(x$inputData[[inpt]],'RasterLayer')){
        inputs <- c(inputs,full.inputs[inpt])
        # GENERATE full set of variables to plot
        var.names <- c(var.names,full.inputs[inpt])
        if (spat.lag){
          var.names <- c(var.names,paste0(full.inputs[inpt],'.1st'))
        }
      }
    }else{
      cat(paste0('NOTE: Selected input ',full.inputs[inpt],' is not a valid variable name. Ignoring ',full.inputs[inpt],' for plotting results.\n'))
    }
  }
  
  # ONLY plot if variables available
  if (length(var.names) == 0){
    cat('\n No plot generated because no numeric variable available for plotting!')
  }else{
    # SPECIFY target frame to plot
    target <- st_as_sf(x$data)
    
    # EXTRACT data frame
    DF <- data.frame(x$data)
    
    special.plot <-function(var.names){
      # SPAN grid of plots
      lat <- NULL
      long <- NULL
      group <- NULL
      mean <- mean(DF[,var.names])
      mean <-round (mean, digits = 0)    
      max <- max(DF[,var.names])
      min <- min(DF[,var.names])
      no_axes <- theme(axis.text = element_blank(),axis.line = element_blank(),axis.ticks = element_blank(),panel.border = element_blank(),panel.grid = element_blank(),axis.title = element_blank())
      p <- ggplot()
      p <- p + geom_sf(inherit.aes = FALSE, data = target, mapping = aes(fill = DF[,var.names]), colour = "white") + expand_limits(x = target$long, y = target$lat) + scale_fill_gradient2(low = "white", mid = "chartreuse3", midpoint = mean , high = muted("chartreuse4"), limits = c(1, max))
      p <- p + ggtitle(var.names)
      p <- p + theme(legend.title=element_blank())
      p <- p + no_axes
      return(p)
    }
    p <- lapply(var.names,special.plot)
    do.call(grid.arrange, c(p,list(ncol=ncol)))
  }
}
