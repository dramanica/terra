\name{plet}

\docType{methods}

\alias{plet}
\alias{plet,missing-method}
\alias{plet,SpatRaster-method}
\alias{plet,SpatVector-method}
\alias{plet,SpatVectorCollection-method}

\alias{lines,leaflet-method}
\alias{points,leaflet-method}

\title{Plot with leaflet}

\description{
Plot the values of a SpatRaster or SpatVector to make an interactive leaflet map that is displayed in a browser.

These methods require the development version of leaflet that you can install with \code{remotes::install_github("rstudio/leaflet")}.
}

\usage{
\S4method{plet}{SpatRaster}(x, y=1, col, alpha=0.8, main=names(x), tiles=NULL, 
   wrap=TRUE, maxcell=500000, legend="bottomright", 
   shared=FALSE, panel=FALSE, collapse=TRUE, map=NULL) 


\S4method{plet}{SpatVector}(x, y="", col, alpha=1, fill=0, main=y, cex=1, lwd=2, popup=TRUE,
   label=FALSE, split=FALSE, tiles=c("Streets", "Esri.WorldImagery", "OpenTopoMap"), 
   wrap=TRUE, legend="bottomright", collapse=FALSE, map=NULL, ...)

\S4method{plet}{SpatVectorCollection}(x, col, alpha=1, fill=0, cex=1, lwd=2, popup=TRUE, 
   label=FALSE, tiles=c("Streets", "Esri.WorldImagery", "OpenTopoMap"), wrap=TRUE,
   legend="bottomright", collapse=FALSE, map=NULL)


\S4method{lines}{leaflet}(x, y, col, lwd=2, alpha=1, ...)

\S4method{points}{leaflet}(x, y, col, cex=1, alpha=1, popup=FALSE, ...)
}

\arguments{
  \item{x}{SpatRaster, SpatVector, or leaflet object}
  \item{y}{missing, or positive integer, or character (variable or layer name) indicating the layer(s) to be plotted. If \code{x} is a SpatRater, you can select multiple layers}
  \item{col}{character. Vector of colors or color generating function}
  \item{alpha}{Number between 0 and 1 to set the transparency for lines (0 is transparent, 1 is opaque)}
  \item{fill}{Number between 0 and 1 to set the transparency for polygon areas (0 is transparent, 1 is opaque)}
  \item{tiles}{character or NULL. Names of background tile providers}
  \item{wrap}{logical. if \code{TRUE}, tiles wrap around}
  \item{maxcell}{positive integer. Maximum number of cells to use for the plot}  
  \item{legend}{character to indicate the legend position ("bottomleft", "bottomright", "topleft" or "topright") or NULL to suppress the legend}
  \item{main}{character. Title for the legend. The length should be 1 if \code{x} is a SpatVector and length nlyr(x) if \code{x} is a SpatVector}
  
  \item{shared}{logical. Should the legend be the same for all rasters (if multiple layers of SpatRaster \code{x} are mapped)}  
  \item{map}{leaflet object}
  \item{...}{additional arguments for drawing points, lines, or polygons passed on the the relevant leaflet function}

  \item{collapse}{logical. Should the layers "control" panel be collapsed?}
  \item{split}{logical. IF \code{TRUE} a check-box is created to toggle each value in code{y} (If \code{x} is a SpatVector)}
  \item{cex}{numeric. point size magnifier. See \code{\link{par}}}
  \item{lwd}{numeric, line-width. See \code{\link{par}}}
  \item{popup}{logical. Should pop-ups be created?}
  \item{label}{logical. Should mouse-over labels be added?}
  \item{panel}{logical. Should SpatRaster layers be shown as a panel"}
}

\seealso{
 \code{\link{plot}}
}

\examples{ 
\dontrun{
if (require(leaflet)) {
if (packageVersion("leaflet") > "2.1.1") {

v <- vect(system.file("ex/lux.shp", package="terra"))
p <- spatSample(as.polygons(v, ext=T), 30)
values(p) = data.frame(id=11:40, name=letters[1:30])

m <- plet(v, "NAME_1", alpha=.4, tiles="")
m <- points(m, p, col="red", cex=2, popup=T)
lines(m, v)

plet(v, "NAME_1", split=TRUE, alpha=.2) |> 
  points(p, col="gray", cex=2, popup=TRUE, 
	clusterOptions = markerClusterOptions()	|> lines(v)

s <- svc(v, p)
names(s) <- c("the polys", "set of points")
plet(s, col=c("red", "blue"), lwd=1)


r <- rast(system.file("ex/elev.tif", package="terra"))
plet(r, main="Hi\nthere") |> lines(v, lwd=1)

plet(r, tiles="Streets") |> lines(v, lwd=2, col="blue")

x <- c(r, 50*classify(r, 5))
names(x) <- c("first", "second")

# each their own legend
plet(x, 1:2, tiles="Streets", collapse=FALSE) |> lines(v, lwd=2, col="blue")

# shared legend
plet(x, 1:2, tiles="Streets", shared=TRUE, collapse=FALSE) |> lines(v, lwd=2, col="blue")

}}}}

\keyword{methods}
\keyword{spatial}

