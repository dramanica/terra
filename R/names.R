# Author: Robert J. Hijmans
# Date:  October 2018
# Version 1.0
# License GPL v3


setMethod("names", signature(x="SpatRaster"),
	function(x) {
		nms <- x@pnt$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)


setMethod("names<-", signature(x="SpatRaster"),
	function(x, value)  {
		if (is.null(value)) {
			value <- rep("", nlyr(x))
		} else {
			value <- enc2utf8(as.character(value))
			if (length(value) != nlyr(x)) {
				error("names<-", "incorrect number of names")
			}
		}
		x@pnt <- x@pnt$deepcopy()
		if (! x@pnt$setNames(value, FALSE)) {
			error("names<-", "cannot set these names")
		}
		return(x)
	}
)


.raster_names_check <- function(x, value, index, validate) {
	value <- enc2utf8(as.character(value))
	if (!all(index == 1:nlyr(x))) {
		n <- names(x)
		n[index] <- value
		value <- n
	}
	if (length(value) != nlyr(x)) {
		error("names<-", "incorrect number of names")
	}
	if (validate) {
		value <- make.names(value, unique = TRUE)
	}
	value
}

.vector_names_check <- function(x, value, index, validate) {
	value <- enc2utf8(as.character(value))
	if (!all(index == 1:ncol(x))) {
		n <- names(x)
		n[index] <- value
		value <- n
	}
	if (length(value) != ncol(x)) {
		error("names<-", "incorrect number of names")
	}
	if (validate) {
		value <- make.names(value, unique = TRUE)
	}
	value
}

setMethod("set.names", signature(x="SpatRaster"),
	function(x, value, index=1:nlyr(x), validate=FALSE)  {
		value <- .raster_names_check(x, value, index, validate)
		if (!x@pnt$setNames(value, FALSE)) {
			error("set.names", "cannot set these names")
		}
		invisible(TRUE)
	}
)


setMethod("names", signature(x="SpatRasterCollection"),
	function(x) {
		nms <- x@pnt$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)


setMethod("names<-", signature(x="SpatRasterCollection"),
	function(x, value) {
		x@pnt <- x@pnt$deepcopy()
		x@pnt$names <- enc2utf8(as.character(value))
		x
	}
)

setMethod("set.names", signature(x="SpatRasterCollection"),
	function(x, value, index=1:length(x), validate=FALSE)  {
		value <- .raster_names_check(x, value, index, validate)
		x@pnt$names <- value
		invisible(TRUE)
	}
)



setMethod("names", signature(x="SpatRasterDataset"),
	function(x) {
		nms <- x@pnt$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)


setMethod("names<-", signature(x="SpatRasterDataset"),
	function(x, value) {
		x@pnt <- x@pnt$deepcopy()
		x@pnt$names <- enc2utf8(as.character(value))
		x
	}
)

setMethod("set.names", signature(x="SpatRasterDataset"),
	function(x, value, index=1:length(x), validate=FALSE)  {
		value <- .raster_names_check(x, value, index, validate)
		x@pnt$names <- value
		invisible(TRUE)
	}
)


setMethod("varnames", signature(x="SpatRasterDataset"),
	function(x) {
		nms <- x@pnt$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)


setMethod("varnames<-", signature(x="SpatRasterDataset"),
	function(x, value) {
		value <- enc2utf8(as.character(value))
		x@pnt <- x@pnt$deepcopy()
		x@pnt$names <- value
		x
	}
)



setMethod("names", signature(x="SpatVector"),
	function(x) {
		nms <- x@pnt$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)

setMethod("names", signature(x="SpatVectorProxy"),
	function(x) {
		nms <- x@pnt$v$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)

setMethod("names<-", signature(x="SpatVector"),
	function(x, value)  {
		if (length(value) != ncol(x)) {
			error("names<-,SpatVector", "incorrect number of names")
		}
		value <- enc2utf8(as.character(value))
		x@pnt <- x@pnt$deepcopy()
		x@pnt$names <- value
		if (any(names(x) != value)) {
			warn("names<-", "some names were changed to make them valid and/or unique")
		}
		return(x)
	}
)

setMethod("set.names", signature(x="SpatVector"),
	function(x, value, index=1:ncol(x), validate=FALSE)  {
		value <- .vector_names_check(x, value, index, validate)
		x@pnt$names <- value
		invisible(TRUE)
	}
)

setMethod("varnames", signature(x="SpatRaster"),
	function(x) {
		nms <- x@pnt$get_sourcenames()
		Encoding(nms) <- "UTF-8"
		nms
	}
)

setMethod("varnames<-", signature(x="SpatRaster"),
	function(x, value)  {
		value <- enc2utf8(as.character(value))
		x@pnt <- x@pnt$deepcopy()
		if (!x@pnt$set_sourcenames(value)) {
			error("varnames<-,SpatRaster", "cannot set these names")
		}
		return(x)
	}
)


setMethod("longnames", signature(x="SpatRasterDataset"),
	function(x) {
		nms <- x@pnt$long_names
		Encoding(nms) <- "UTF-8"
		nms
	}
)


setMethod("longnames", signature(x="SpatRaster"),
	function(x) {
		nms <- x@pnt$get_sourcenames_long()
		Encoding(nms) <- "UTF-8"
		nms
	}
)

setMethod("longnames<-", signature(x="SpatRasterDataset"),
	function(x, value)  {
		x@pnt <- x@pnt$deepcopy()
		x@pnt$long_names <- enc2utf8(as.character(value))
		return(x)
	}
)


setMethod("longnames<-", signature(x="SpatRaster"),
	function(x, value)  {
		x@pnt <- x@pnt$deepcopy()
		value <- enc2utf8(as.character(value))
		if (!x@pnt$set_sourcenames_long(value)) {
			error("longnames<-,SpatRaster", "cannot set these names")
		}
		return(x)
	}
)


setMethod("names", signature(x="SpatVectorCollection"),
	function(x) {
		nms <- x@pnt$names
		Encoding(nms) <- "UTF-8"
		nms
	}
)


setMethod("names<-", signature(x="SpatVectorCollection"),
	function(x, value) {
		x@pnt <- x@pnt$deepcopy()
		x@pnt$setNames(enc2utf8(as.character(value)), FALSE)
		x
	}
)
