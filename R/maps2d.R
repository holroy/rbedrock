#' @export
read_2dmaps <- function(con) {
    if (is.character(con)) {
        con <- file(con, "rb")
        on.exit(close(con))
    } else if (is.raw(con)) {
        con <- rawConnection(con)
        on.exit(close(con))
    }
    h <- readBin(con, integer(), n=256L, size=2L, endian="little", signed = TRUE)
    b <- readBin(con, integer(), n=256L, size=1L, endian="little", signed = FALSE)
    list(height_map = h, biome_ids = b)
}

#' @export
get_biomes <- function(db, x, z, dimension, return_names=TRUE) {
    k <- .process_strkey_args(x,z,dimension,tag=45L)
    
    dat <- db$mget(k, as_raw = TRUE) %>% purrr::compact()

    biomes <- dat %>% purrr::map(function(x) {
        y <- read_2dmaps(x)$biome_ids
        if(return_names) {
            y <- .BIOME_LIST_INV[y+1]
        }
        dim(y) <- c(16,16)
        y
    })

    biomes
}

# this lists was generated from a running instance of
# bedrock dedicated server 1.16.0
.BIOME_LIST <- c(
    ocean = 0L,
    plains = 1L,
    desert = 2L,
    extreme_hills = 3L,
    forest = 4L,
    taiga = 5L,
    swampland = 6L,
    river = 7L,
    hell = 8L,
    the_end = 9L,
    frozen_river = 11L,
    ice_plains = 12L,
    ice_mountains = 13L,
    mushroom_island = 14L,
    mushroom_island_shore = 15L,
    beach = 16L,
    desert_hills = 17L,
    forest_hills = 18L,
    taiga_hills = 19L,
    extreme_hills_edge = 20L,
    jungle = 21L,
    jungle_hills = 22L,
    jungle_edge = 23L,
    deep_ocean = 24L,
    stone_beach = 25L,
    cold_beach = 26L,
    birch_forest = 27L,
    birch_forest_hills = 28L,
    roofed_forest = 29L,
    cold_taiga = 30L,
    cold_taiga_hills = 31L,
    mega_taiga = 32L,
    mega_taiga_hills = 33L,
    extreme_hills_plus_trees = 34L,
    savanna = 35L,
    savanna_plateau = 36L,
    mesa = 37L,
    mesa_plateau_stone = 38L,
    mesa_plateau = 39L,
    warm_ocean = 40L,
    deep_warm_ocean = 41L,
    lukewarm_ocean = 42L,
    deep_lukewarm_ocean = 43L,
    cold_ocean = 44L,
    deep_cold_ocean = 45L,
    frozen_ocean = 46L,
    deep_frozen_ocean = 47L,
    bamboo_jungle = 48L,
    bamboo_jungle_hills = 49L,
    sunflower_plains = 129L,
    swampland_mutated = 134L,
    ice_plains_spikes = 140L,
    roofed_forest_mutated = 157L,
    cold_taiga_mutated = 158L,
    savanna_mutated = 163L,
    savanna_plateau_mutated = 164L,
    soulsand_valley = 178L,
    crimson_forest = 179L,
    warped_forest = 180L,
    basalt_deltas = 181L
)

# invert the list
.BIOME_LIST_INV <- character()
.BIOME_LIST_INV[.BIOME_LIST+1] <- names(.BIOME_LIST)