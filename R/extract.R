# Author: Robert J. Hijmans
# Date : November 2018
# Version 1.0
# License GPL v3


.big_number_warning <- function() {
# this warning should be given by C
	warn("big number", "cell numbers larger than ", 2^.Machine$double.digits, " are approximate")
}


ext_from_rc <- function(x, r1, r2, c1, c2){
	e <- as.vector(ext(x))
	r <- res(x)
	c1 <- min(max(c1, 1), ncol(x))
	c2 <- min(max(c2, 1), ncol(x))
	if (c1 > c2) {
		tmp <- c1
		c1 <- c2
		c2 <- tmp
	}
	r1 <- min(max(r1, 1), nrow(x))
	r2 <- min(max(r2, 1), nrow(x))
	if (r1 > r2) {
		tmp <- r1
		r1 <- r2
		r2 <- tmp
	}

	xn <- xFromCol(x, c1) - 0.5 * r[1]
	xx <- xFromCol(x, c2) + 0.5 * r[1]
	yx <- yFromRow(x, r1) + 0.5 * r[2]
	yn <- yFromRow(x, r2) - 0.5 * r[2]
	ext(c(sort(c(xn, xx))), sort(c(yn, yx)))
}



extractCells <- function(x, y, method="simple", cells=FALSE, xy=FALSE, layer=NULL, raw=FALSE) {

	#value <- match.arg(tolower(value), c("data.frame", "list", "matrix"))
	method <- match.arg(tolower(method), c("simple", "bilinear"))

	nl <- nlyr(x)
	useLyr <- FALSE
	if (!is.null(layer) && nl > 1) {
		if (any(is.na(layer))) {error("extract", "argument 'layer' cannot have NAs")}
		stopifnot(length(layer) == nrow(y))
		if (is.numeric(layer)) {
			layer <- round(layer)
			stopifnot(min(layer) > 0 & max(layer) <= nlyr(x))
		} else {
			layer <- match(layer, names(x))
			if (any(is.na(layer))) error("extract", "names in argument 'layer' do not match names(x)")
		}
		useLyr <- TRUE
	}
	cn <- names(x)
	opt <- spatOptions()
	if ((method == "bilinear") && (NCOL(y) > 1)) {
		e <- x@pnt$bilinearValues(y[,1], y[,2])
	} else {
		if (NCOL(y) == 2) {
			y <- cellFromXY(x, y)
		}
		e <- x@pnt$extractCell(y-1)
	}

	e <- do.call(cbind, e)
	cn <- names(x)
	nc <- nl
	if (cells) {
		cn <- c(cn, "cell")
		nc <- nc + 1
		if (NCOL(y) == 2) {
			e <- cbind(e, cellFromXY(x, y))
		} else {
			e <- cbind(e, y)
		}
	}
	if (xy) {
		cn <- c(cn, "x", "y")
		nc <- nc + 2
		if (NCOL(y) == 1) {
			y <- xyFromCell(x, y)
		}
		e <- cbind(e, y)
	}
	colnames(e) <- cn

	if (!raw) {
		if (method != "simple") {
			e <- as.data.frame(e)
		} else {
			e <- .makeDataFrame(x, e)
		}
	}

	if (useLyr) {
		idx <- cbind(e[,1], layer[e[,1]]+1)
		ee <- cbind(e[,1,drop=FALSE], names(x)[idx[,2]-1], value=e[idx])
		colnames(ee)[2] <- "layer"
		if (ncol(e) > (nl+1)) {
			cbind(ee, e[,(nl+1):ncol(e), drop=FALSE])
		} else {
			ee
		}
	} else {
		e
	}
}

use_layer <- function(e, y, layer, nl) {
	if (!is.null(layer) && nl > 1) {
		if (any(is.na(layer))) {error("extract", "argument 'layer' cannot have NAs")}
		if (length(layer) == 1) {
			lyr_name <- layer
			layer <- as.character(y[[layer,drop=TRUE]])
		} else {
			lyr_name <- "layer"
			stopifnot(length(layer) == nrow(y))
		}
		if (is.numeric(layer)) {
			layer <- round(layer)
			stopifnot(min(layer) > 0 & max(layer) <= nl)
		} else {
			layer <- match(layer, colnames(e))
			if (any(is.na(layer))) error("extract", "names in argument 'layer' do not match names(x)")
		}

		idx <- cbind(e[,1], layer[e[,1]])
		ee <- data.frame(e[,1,drop=FALSE], names(e)[idx[,2]-1], value=e[idx])
		colnames(ee)[2] <- lyr_name
		if (ncol(e) > (nl+1)) {
			e <- cbind(ee, e[,(nl+1):ncol(e), drop=FALSE])
		} else {
			e <- ee
		}
	}
	e
}


extract_table <- function(x, y, ID=FALSE, weights=FALSE, exact=FALSE, touches=FALSE, na.rm=FALSE) {

	if (weights && exact) {
		exact = FALSE
	}
	opt <- spatOptions()

	if (weights | exact) {
		wtable <- function(p, na.rm=FALSE) {
			n <- length(p)
			w <- p[[n]]
			p[[n]] <- NULL
			do.call( rbind, 
				lapply(1:length(p), function(i) {
					x <- p[[i]]
					j <- is.na(x)
					if (na.rm) {
						x <- x[!j]
						w <- w[!j]
					} else if (any(j)) {
						w[] <- NA
					}
					data.frame(layer=i, aggregate(w, list(x), sum, na.rm=FALSE))
				})
			)
		}
		
		e <- x@pnt$extractVector(y@pnt, touches[1], "simple", FALSE, FALSE, 
			isTRUE(weights[1]), isTRUE(exact[1]), opt)
		x <- messages(x, "extract")
		e <- lapply(e, wtable, na.rm=na.rm)
		e <- lapply(1:length(e), function(i) cbind(ID=i, e[[i]]))
		e <- do.call(rbind, e)
		colnames(e)[3:4] <- c("group", "value")
		out <- vector("list", nlyr(x))
		for (i in 1:nlyr(x)) {
			ee <- e[e[,2] == i, ]
			ee <- replace_with_label(x[[i]], ee, 3)
			ee <- stats::reshape(ee, idvar=c("ID", "layer"), timevar="group", direction="wide")
			colnames(ee) <- gsub("value.", "", colnames(ee))
			ee$layer <- NULL
			if (!ID) {
				ee$ID <- NULL
			}
			if (na.rm) {
				ee[is.na(ee)] <- 0
			}
			out[[i]] <- ee
		}
		if (nlyr(x) == 1) return(out[[1]]) else return(out)
	} else {
		e <- x@pnt$extractVectorFlat(y@pnt, "", FALSE, touches[1], "", FALSE, FALSE, FALSE, FALSE, opt)
		x <- messages(x, "extract")
		e <- data.frame(matrix(e, ncol=nlyr(x)+1, byrow=TRUE))
		colnames(e) <- c("ID", names(x))
		id <- e[,1,drop=FALSE]
		e <- cbind(id, .makeDataFrame(x, e[,-1,drop=FALSE]))
		cn <- colnames(e)
		out <- vector("list", ncol(e)-1)
		for (i in 2:ncol(e)) {
			fixname <- TRUE
			if (!is.factor(e[,i])) {
				fixname <- FALSE
				e[,i]  <- as.factor(e[,i])
			}
			tb <- aggregate(e[,i,drop=FALSE], e[,1,drop=FALSE], table)
			tb <- cbind(tb[,1,drop=FALSE], tb[,2,drop=FALSE])
			if (fixname) colnames(tb) <- gsub(cn[i], "", colnames(tb))
			if (!ID) {
				tb$ID <- NULL
			}
			tb$layer <- NULL
			out[[i-1]] <- tb
		}
		if (ncol(e) == 2) return(out[[1]]) else return(out)
	}
}



extract_fun <- function(x, y, fun, ID=TRUE, weights=FALSE, exact=FALSE, touches=FALSE, layer=NULL, bind=FALSE, na.rm=FALSE) {

	opt <- spatOptions()

	e <- x@pnt$extractVectorFlat(y@pnt, fun, na.rm, touches[1], "", FALSE, FALSE, weights, exact, opt)
	x <- messages(x, "extract")

	nl <- nlyr(x)
	e <- data.frame(matrix(e, ncol=nl, byrow=TRUE))
	colnames(e) <- names(x)

	if (!is.null(layer)) {
		e <- cbind(ID=1:nrow(e), e)
		e <- use_layer(e, y, layer, nlyr(x))
		if (!ID || bind) {
			e$ID <- NULL
		}
		ID <- FALSE
	} 
	if (bind) {
		if (nrow(e) == nrow(y)) {
			e <- cbind(y, e)
		} else {
			warn("extract", "cannot return a SpatVector because the number of records extracted does not match he number of rows in y (perhaps you need to use a summarizing function")
		}
	} else if (ID) {
		e <- cbind(ID=1:nrow(e), e)
	}
	e
}


do_fun <- function(x, e, fun, ...) {		
	fun <- match.fun(fun)
	e <- aggregate(e[,-1,drop=FALSE], e[,1,drop=FALSE], fun, ...)
	m <- sapply(e, NCOL)
	if (any(m > 1)) {
		cn <- names(x)
		e <- do.call(cbind, as.list(e))
		skip <- (length(cn) - nlyr(x))
		nms <- colnames(e)
		snms <- nms[(skip+1):length(nms)]
		mr <- max(m)
		if (!all(snms=="")) {
			snms <- paste0(rep(names(x), each=mr), ".", snms)
		} else {
			snms <- paste0(rep(names(x), each=mr), ".", rep(1:mr))
		}
		snms <- c(cn[1:skip], snms)
		colnames(e) <- snms
		e <- data.frame(e)
	}
	e
}


setMethod("extract", signature(x="SpatRaster", y="SpatVector"),
function(x, y, fun=NULL, method="simple", cells=FALSE, xy=FALSE, ID=TRUE, weights=FALSE, exact=FALSE, touches=is.lines(y), layer=NULL, bind=FALSE, raw=FALSE, ...) {

	geo <- geomtype(y)
	if (geo == "points") {		
		if (weights || exact) {
			method <- "bilinear"
			weights <- FALSE
			exact <- FALSE
		} 
		# method <- match.arg(tolower(method), c("simple", "bilinear"))
	} else if (!is.null(fun)) { # nothing to summarize for points
		txtfun <- .makeTextFun(fun)
		if (inherits(txtfun, "character")) {
			if (txtfun == "table") {
				if (!is.null(layer)) {
					warn("extract", "argument 'layer' is ignored when 'fun=table'")
				}
				e <- extract_table(x, y, ID=ID, weights=weights, exact=exact, touches=touches, ...)
			} else {
				e <- extract_fun(x, y, txtfun, ID=ID, weights=weights, exact=exact, touches=touches, bind=bind
				, layer=layer, ...)
			}
			return(e)
		} else if (weights || exact) {
			error("extract", "if 'weights' or 'exact' is TRUE, you can only use functions mean, sum, min, max and table")
		}
		xy <- cells <- FALSE
		raw <- TRUE
	} 
	
	opt <- spatOptions()
	e <- x@pnt$extractVectorFlat(y@pnt, "", FALSE, touches[1], method, isTRUE(cells[1]), isTRUE(xy[1]), isTRUE(weights[1]), isTRUE(exact[1]), opt)
	x <- messages(x, "extract")

	cn <- c("ID", names(x))
	nc <- nl <- nlyr(x)
	if (cells) {
		cn <- c(cn, "cell")
		nc <- nc + 1
	}
	if (xy) {
		cn <- c(cn, "x", "y")
		nc <- nc + 2
	}
	if (weights) {
		cn <- c(cn, "weight")
		nc <- nc + 1
	} else if (exact) {
		cn <- c(cn, "fraction")
		nc <- nc + 1
	}
	if (geo == "points") {
		## this was? should be fixed upstream
		if (nc == nl) {
			e <- matrix(e, ncol=nc)
		} else {
			e <- matrix(e, ncol=nc, byrow=TRUE)
		}
		e <- cbind(1:nrow(e), e)
		if (nrow(e) > nrow(y)) { #multipoint
			g <- geom(y)
			e[,1] <- g[,1]
		}
	} else {
		e <- matrix(e, ncol=nc+1, byrow=TRUE)
	}
	colnames(e) <- cn
	if (!is.null(fun)) {
		e <- as.data.frame(e)
		e <- do_fun(x, e, fun, ...)
	}
	
	if (cells) {
		cncell <- cn =="cell"
		e[, cncell] <- e[, cncell] + 1
	}

	if (!raw) {
		if (method != "simple") {
			e <- as.data.frame(e)
		} else {
			id <- data.frame(e[,1,drop=FALSE])
			e <- cbind(id, .makeDataFrame(x, e[,-1,drop=FALSE]))
		}
	}
	
	e <- use_layer(e, y, layer, nl)

	if (bind) {
		if (nrow(e) == nrow(y)) {
			e <- cbind(y, e[,-1,drop=FALSE])
		} else {
			warn("extract", "cannot return a SpatVector because the number of records extracted does not match the number of rows in y (perhaps you need to use a summarizing function")
		}
	} else if (!ID) {
		e <- e[,-1,drop=FALSE]
	}
	e
})



setMethod("extract", signature(x="SpatRaster", y="sf"),
	function(x, y, fun=NULL, method="simple", cells=FALSE, xy=FALSE, ID=TRUE, weights=FALSE, exact=FALSE, touches=is.lines(y), layer=NULL, bind=FALSE, ...) {
		y <- vect(y)
		extract(x, y, fun=fun, method=method, cells=cells, xy=xy, ID=ID, weights=weights, exact=exact, touches=touches, layer=layer, bind=bind, ...)
	}
)



setMethod("extract", signature(x="SpatRaster", y="data.frame"),
function(x, y, ...) {
	if (ncol(y) != 2) {
		error("extract", "extract expects a 2 column data.frame of x and y coordinates")
	}
	v <- vect(y, colnames(y))
	extract(x, v, ...)
})


setMethod("extract", signature(x="SpatRaster", y="numeric"),
function(x, y, xy=FALSE) {
	y <- round(y)
	y[(y < 1) | (y > ncell(x))] <- NA
	v <- .extract_cell(x, y, drop=TRUE)
	if (xy) {
		v <- cbind(xyFromCell(x, y), v)
	}
	v
})

setMethod("extract", signature(x="SpatRaster", y="matrix"),
function(x, y, cells=FALSE, method="simple") {
	.checkXYnames(colnames(y))
	method <- match.arg(tolower(method), c("simple", "bilinear"))
	if (method != "simple") {
		y <- vect(y)
		return(extract(x, y, method=method, ID=FALSE))
	}
	y <- cellFromXY(x, y)
	if (cells) {
		cbind(cell=y, extract(x, y))
	} else {
		extract(x, y)
	}
})

setMethod("extract", signature(x="SpatRaster", y="SpatExtent"),
function(x, y, cells=FALSE, xy=FALSE) {
	y <- cells(x, y)
	v <- extract(x, y, xy=xy)
	if (cells) {
		v <- cbind(cell=y, v)
	}
}
)


setMethod("extract", c("SpatVector", "SpatVector"),
function(x, y) {

	e <- relate(y, x, "coveredby", pairs=TRUE, na.rm=FALSE)
	if (ncol(x) > 0) {
		d <- as.data.frame(x)
		e <- data.frame(id.y=e[,1], d[e[,2], ,drop=FALSE])
		rownames(e) <- NULL
	} else {
		colnames(e) <- c("id.y", "id.x")
	}
	e
})


setMethod("extract", signature(x="SpatVector", y="matrix"),
function(x, y) {
	stopifnot(ncol(y) == 2)
	.checkXYnames(colnames(y))
	y <- vect(y)
	extract(x, y)
})

setMethod("extract", signature(x="SpatVector", y="data.frame"),
function(x, y) {
	extract(x, as.matrix(y))
})


setMethod("extract", signature(x="SpatRasterCollection", y="ANY"),
function(x, y, ...) {
	lapply(x, function(r) extract(r, y, ...))
}
)

setMethod("extract", signature(x="SpatRasterDataset", y="ANY"),
function(x, y, ...) {
	lapply(x, function(r) extract(r, y, ...))
}
)
