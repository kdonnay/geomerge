\name{geomerge}
\alias{geomerge}
\title{
Geospatial Data Integration
}
\description{
This function conducts a series of spatial joins for Geographic Information Systems (GIS) data. It integrates three of R's most commonly used GIS data classes - polygons, points and rasters. With flexible options for assignment rules and including the calculation of spatial and temporal lags, \code{geomerge} returns a spatial (panel) dataset in the form of a \code{SpatialPolygonsDataFrame} that users may import into any predictive statistical analysis.
}
\note{
\code{geomerge} exclusively merges data using the global WGS84 coordinate reference system (CRS) to ensure that areal statistics are accurate at all scales. If data are entered that are using a different and/or projected CRS, the tool automatically first transforms the data. This on-the-fly transformation, however, may be very slow and it is advised to always enter inputs in WGS84.
}
\usage{
geomerge(...,target=NULL,time=NA,time.lag=TRUE,spat.lag=TRUE,
             zonal.fun=sum, assignment="max(area)",population.data = NA,
             point.agg = "cnt",t_unit="days",silent=FALSE)
}
\arguments{
  \item{\dots}{
  input datasets and, if provided, optional arguments. See Details.  
}
  \item{target}{
  \code{SpatialPolygonsDataFrame} representing desired units of analysis. See Details. 
}
  \item{time}{
  temporal window for dynamic temporal binning of point data. Required format is \code{c(start_date, end_date, interval_length)}, each specified as String. Default = \kbd{NA}. See Details.
}
  \item{time.lag}{
  Boolean indicating whether or not first and second order temporal lag values of all variables are returned. Only affects dynamic point data integration. Default = \kbd{TRUE}.
}
  \item{spat.lag}{
  Boolean indicating whether or not first and second order spatial lag values of all variables are returned. Default = \kbd{TRUE}.
}
  \item{zonal.fun}{
  object of class \kbd{function} applied to values of \code{RasterLayer} when generating zonal statistics for each target polygon. Default = \kbd{sum}. See Details.
}
  \item{assignment}{
  identification of either population- or area-weighting assignment rules when handling \code{SpatialPolygonsDataFrame} joins to \code{target}. Default = \kbd{"max(area)"}. See Details.
}
  \item{population.data}{
  specifies data used for weighting if a population-based \code{assignment} rule is selected. See Details.
}
  \item{point.agg}{
  specification of aggregation format for data of type \code{SpatialPointsDataFrame}. Default = \kbd{"cnt"}. See Details.
}
  \item{t_unit}{
  temporal unit used for dynamic point aggregation. Default = \kbd{"days"}.
}
  \item{silent}{
  Boolean switch to suppress any (non-critical) warnings and messages. Default = \kbd{FALSE}.
}
}
\details{
\code{geomerge} accepts any number of data inputs of the most common spatial data classes in R - \code{SpatialPolygonsDataFrame}, \code{SpatialPointsDataFrame}, and \code{RasterLayer}. The \code{target} they are merged to may be of any shape but must be a \code{SpatialPolygonsDataFrame}. The extent of each data input should at least match the extent of the \code{target}; if not, the package returns a warning. In order to perform accurate area calculations at any scale, \code{geomerge} projects any data geometry into WGS84. Input data (including \code{target}) not in WGS84 are automatically re-projected.

\code{geomerge} assumes that all inputs of type \code{SpatialPolygonsDataFrame} and \code{RasterLayer} are static and contemporary. If polygons or raster are changing, we advise to simply rerun \code{geomerge} for each interval in which data are static and contemporary. The package allows for dynamic integration of all inputs that are a \code{SpatialPointsDataFrame}, i.e., one can, for example, automatically generate the counts of events that occur within a specific unit of \code{target} within a specific time period. Further details are given below.

If \code{SpatialPolygonsDataFrame} data are joined to \code{target}, they must contain only one column with the data of interest. The package also accepts the short-hand variable specification using the standard "$" notation to denote the selection of a specific variable from the \code{SpatialPolygonsDataFrame}. \code{RasterLayer} are by default single-valued. These data may be of class \kbd{factor} or \kbd{numeric}.

If \code{SpatialPointsDataFrame} are joined to \code{target} they must have one column coding the variable of interest and, if points carry timestamps, dates must be given in a second column \kbd{timestamp} and formatted as a UTC date string with format \kbd{"YYYY-MM-DD"} or \kbd{"YYYY-MM-DD hh:mm:ss"}.

In practice, our input logic implies that if more than one variable of interest are to be merged to \code{target}, statically or dynamically, each has to be separately entered as argument. Note that variable names in \code{target} derive from the name of the input data and it is therefore advised to use meaningful labels for input data.

In merging \code{SpatialPolygonsDataFrame} values to units of analysis given by \code{target}, users have a choice among a number of different \code{assignment} rules based on area overlap and population size. Area-based assignment generally can take the values \kbd{"max(area)"} or \kbd{"min(area)"}, i.e., the value assigned to a given unit in \code{target} comes from that polygon in the \code{SpatialPolygonsDataFrame} with maximal or minimal area overlap respectively. If the value of interest is of class \kbd{numeric}, the user may also choose \kbd{"weighted(area)"}, i.e., the values is assigned as the area-weighted average of the values in all polygons intersecting a given unit in \code{target}.

The assignment rules \kbd{"max(pop)"}, \kbd{"min(pop)"} and \kbd{"weighted(pop)"} (the latter again for \kbd{numeric} variables only) analogously use the population value given by \code{population.data} in overlapping areas as basis for assignment. If any of them is selected in the \code{assignment} argument, users must provide \code{population.data} as a \code{RasterLayer}. The geographical resolution of \code{population.data} should be the same or better than that of \code{target}. The zonal statistic used for population within overlapping polygons is \code{sum}.

When a \code{SpatialPointsDataFrame} is merged to \code{target}, one of two operations can be performed. For \code{point.agg = "cnt"} the function calculates the sum of the number of locations that fall within each unit of \code{target}. For numerical variables of interest, \code{point.agg = "sum"} returns  the sum across for all values associated with points within each unit of \code{target}. If different aggregation formats are to be applied to different \code{SpatialPointsDataFrame} inputs, these have to be specified as a character vector, i.e., \code{point.agg = c("sum", "cnt")}, in the order of inputs.

Values for inputs of type \code{SpatialPointsDataFrame} are either calculated statically across the entire frame if \code{time = NA} or dynamically within a given time period that can be specified using \code{time = c(start_date, end_date, interval_length)}. All three inputs must be Strings where \code{interval_length} is defined in multiples of \code{t_unit}. The default value is \code{t_unit = "days"}, the package also accepts inputs of \kbd{"secs"}, \kbd{"mins"}, \kbd{"hours"}, \kbd{"months"} or \kbd{"years"}.

Zonal statistics are applied to objects of class \code{RasterLayer} that are joined to \code{target}. The specific operations are defined in the function call using the argument \code{zonal.fun} and each is added into the result. Any zonal statistics compatible with the \code{extract} function in \pkg{terra} is accepted. Note that \code{geomerge} does not accept raster stacks. If you have raster stacks they must be separated and the layers integrated separately into the function. 

If \code{spat.lag = TRUE} spatial lags of all \kbd{numeric} variables from a \code{SpatialPolygonsDataFrame} or \code{RasterLayer} joined to \code{target} polygons are returned using first and also second order neighboring weights matrices. The package assigns \code{target} polygons the mean value of units within each neighborhood. When dynamic point aggregation is run and \code{time.lag = TRUE}, \code{geomerge} returns the values of every target polygon, as well as its first and second order neighboring unit averages, separately, at time t-1 and t-2 defined by \code{interval} in the argument \code{time}.
}
\value{
Returns an object of class \kbd{"geomerge"}.

The functions \code{summary}, \code{print}, \code{plot} overload the standard outputs for objects of type \code{geomerge} providing summary information and and visualizations specific to the output object. An object of class \kbd{"geomerge"} is a list containing the following three components:

\item{data}{\code{SpatialPolygonsDataFrame} that contains all information merged with the \code{target} layer. Column names are assigned the name of the input data object separated by "." from a short description of the calculation, as well as modifiers such as ".1st" and ".2nd" for first- and second-order neighborhoods of \code{target}. In the case of dynamic point data aggregation, ".t_1" and ".t_2" are used to label first- and second-order temporal lags. For example, if \code{geomerge} is told to use a \code{SpatialPointsDataFrame} called \kbd{"vio"} to count incidents of conflict contained within units of \code{target}, the default output would include columns named \kbd{"vio.cnt"}, \kbd{"vio.cnt.t_1"}, \kbd{"vio.cnt.t_2"}, \kbd{"vio.cnt.1st"}, \kbd{"vio.cnt.1st.t_1"}, \kbd{"vio.cnt.1st.t_2"}, \kbd{"vio.cnt.2nd"}, \kbd{"vio.cnt.2nd.t_1"}, \kbd{"vio.cnt.2nd.t_2"}.
}

\item{inputData}{List containing the spatial objects used as input.}

\item{parameters}{List containing information on all input parameters used during integration.}

}

\references{
Andrew M. Linke, Karsten Donnay. (2017). "Scale Variability Misclassification: The Impact of Spatial Resolution on Effect Estimates in the Geographic Analysis of Foreign Aid and Conflict." Paper presented at the \emph{International Studies Association Annual Meeting}, February 22-25 2017, Baltimore.
}
\author{
  Karsten Donnay and Andrew M. Linke.
}
\seealso{
\code{\link{geomerge-package}}, \code{\link{print.geomerge}}, \code{\link{plot.geomerge}}, \code{\link{summary.geomerge}}, \code{\link{generateGrid}}
}
\examples{
data(geomerge)

# 1) Simple static integration of polygon data
output <- geomerge(geoEPR,target=states,silent=TRUE)
summary (output)

\donttest{
# 2) Static integration for point, polygon, raster data
output <- geomerge(ACLED$EVENT_TYPE,AidData$project_id,geoEPR,
		   gpw,na.rm=TRUE,target=states)
summary(output)
plot(output)

# 3) Dynamic point data integration for numeric variables
output <- geomerge(ACLED$FATALITIES,AidData$commitme_1,geoEPR,
		   target=states,time=c("2011-01-01", "2011-12-31","1"),
		   t_unit='months',point.agg='sum')
summary(output)
plot(output)

# 4) Population weighted assignment
output <- geomerge(geoEPR,target=states,assignment='max(pop)',
		   population.data = gpw)
summary(output)
plot(output)
}
}