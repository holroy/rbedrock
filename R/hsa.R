#' Get HardcodedSpawnArea information from a world.
#'
#' @param db A bedrockdb object.
#' @param x,z,dimension Chunk coordinates to extract HSA data from.
#'    x can also be a character vector of db keys and any keys not
#'    representing HSA data will be silently dropped.
#' @return A table containing HSA and spawn-spot information.
#' @examples
#' db <- bedrockdb("x7fuXRc8AAA=")
#' hsa <- get_hsa(db)
#' db$close()
#'
#' @export
get_hsa <- function(db, x=db$keys(), z, dimension) {
    keys <- .process_strkey_args(x,z,dimension,tag=57L)

    dat <- db$mget(keys, as_raw = TRUE) %>% purrr::compact()

    if(length(dat) == 0) {
        hsa <- tibble::tibble(type = character(), key = character(),
                      x1 = numeric(), y1 = numeric(), z1 = numeric(),
                      x2 = numeric(), y2 = numeric(), z2 = numeric(),
                      tag = numeric(),
                      xspot = numeric(), yspot = numeric(), zspot = numeric(),
                      dimension = numeric()
            )
        return(hsa)
    }

    hsa <- dat %>% purrr::map_dfr(~tibble::as_tibble(read_hsa_data(.)), .id="key")

    hsa$dimension <- hsa$key %>% stringr::str_extract("[^:]+(?=:57$)") %>% as.integer()
    
    hsa$type <- dplyr::recode(hsa$tag,
        "NetherFortress",
        "SwampHut",
        "OceanMonument",
        "4", # removed cat HSA
        "PillagerOutpost",
        "6"  # removed cat HSA
    )
    hsa %>% dplyr::select("type", dplyr::everything())
}

#' Add a HardcodedSpawnArea to a world.
#'
#' If the bounding box of the HSA overlaps multiple chunks, one HSA will be added per chunk.
#'
#' @param db A bedrockdb object.
#' @param x1,y1,z1,x2,y2,z2 HSA bounding box coordinates.
#' @param tag The type of HSA. 1 = NetherFortress, 2 = SwampHut, 3 = OceanMonument, 5 = PillagerOutpost.
#'  4 and 6 are no longer used by the game.
#' @param dimension The dimension that the HSA should be in. 0 = Overworld, 1 = Nether.
#' @return A table containing information about the added HSAs.
#' @examples
#' db <- bedrockdb("x7fuXRc8AAA=")
#' put_hsa(db, 0, 60, 0, 15, 70, 15, 2, 0)
#' db$close()
#'
#' @export
put_hsa <- function(db, x1, y1, z1, x2, y2, z2, tag, dimension) {
    # convert tag as necessary
    if(is.character(tag)) {
        tag <- switch(tag, NetherFortress = 1, SwampHut = 2, OceanMonument = 3, PillagerOutpost = 5)
    }
    if(missing(dimension)) {
        dimension <- (tag == 1)*1L
    }

    # identify all chunks that this HSA overlaps
    x <- range(x1, x2)
    y <- range(y1, y2)
    z <- range(z1, z2)
    chunk_x1 <- x[1] %/% 16L
    chunk_z1 <- z[1] %/% 16L
    chunk_x2 <- x[2] %/% 16L
    chunk_z2 <- z[2] %/% 16L

    # create hsa for each chunk
    ret <- NULL
    for (chunk_x in seq.int(chunk_x1, chunk_x2)) {
        for (chunk_z in seq.int(chunk_z1, chunk_z2)) {
            hx1 <- max(x[1], chunk_x * 16L)
            hx2 <- min(x[2], chunk_x * 16L + 15L)
            hz1 <- max(z[1], chunk_z * 16L)
            hz2 <- min(z[2], chunk_z * 16L + 15L)
            hy1 <- y[1]
            hy2 <- y[2]
            hsa <- matrix(c(hx1, hy1, hz1, hx2, hy2, hz2, tag), 1L, 7L)
            ret <- rbind(ret, hsa)
            key <- create_chunk_key(chunk_x, chunk_z, dimension, 57L)
            dat <- db$get(key, as_raw = TRUE)
            if (!is.null(dat)) {
                hsa <- rbind(read_hsa_data(dat)[, 1L:7L], hsa)
            }
            hsa <- write_hsa_data(hsa)
            db$put(key, hsa)
        }
    }
    ret
}

#' @export
read_hsa_data <- function(rawval) {
    con <- rawConnection(rawval)
    on.exit(close(con))

    len <- readBin(con, integer(), n = 1, size = 4)
    out <- integer()
    for (i in 1:len) {
        aabb <- readBin(con, integer(), n = 6, size = 4)
        tag <- readBin(con, integer(), n = 1, size = 1)
        out <- rbind(out, c(aabb, tag))
    }
    colnames(out) <- c("x1", "y1", "z1", "x2", "y2", "z2", "tag")
    y <- pmax.int(out[, "y1"], out[, "y2"]) - 
        ifelse(out[,"tag"] == 1L | out[,"tag"] == 5L, 0L, 3L)
    out <- cbind(out, xspot = out[, "x1"] + (out[, "x2"] - out[, "x1"] + 1L) %/% 2L)
    out <- cbind(out, yspot = y-1L)
    out <- cbind(out, zspot = out[, "z1"] + (out[, "z2"] - out[, "z1"] + 1L) %/% 2L)
    rownames(out) <- NULL
    out
}

#' @export
write_hsa_data <- function(hsa) {
    con <- rawConnection(raw(0), "wb")
    on.exit(close(con))

    len <- nrow(hsa)
    writeBin(as.integer(len), con, size = 4, endian = "little")
    for (i in 1:len) {
        n <- as.integer(hsa[i, ])
        writeBin(n[1:6], con, size = 4, endian = "little")
        writeBin(n[7], con, size = 1, endian = "little")
    }

    rawConnectionValue(con)
}
