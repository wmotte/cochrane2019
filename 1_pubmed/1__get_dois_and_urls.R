#!/usr/bin/Rscript --no-save --no-restore
#
# Wim Otte (w.m.otte@umcutrecht.nl)
# 31 July 2019
########################################################################

library( "rentrez" )

###################################
# FUNCTIONS
###################################

###
# Get dois.
##
get_dois <- function()
{
	term <- "\"cochrane database syst rev\"[journal] AND (\"2016/01/01\"[PDAT] : \"2019/07/31\"[PDAT])"
	results <- rentrez::entrez_search( "pubmed", term = term, retmax = 30000 )
	length( results$ids ) # 2646

	# create an index that splits
	idx <- split( seq( 1, length( results$ids ) ), ceiling( seq_along( seq( 1, length( results$ids ) ) ) / 100 ) )

	# create an empty list to hold summary contents
	all <- NULL

	for( i in 1:length( idx ) )
	{
		pids <- idx[ i ]
		pmin <- min( pids[[ 1 ]] )
		pmax <- max( pids[[ 1 ]] )

		print( paste0( "idx: ", i, " min: ", pmin, " max: ", pmax ) )
	
		tiabs <- rentrez::parse_pubmed_xml( rentrez::entrez_fetch( db = "pubmed", id = results$ids[ pmin:pmax ], rettype = "xml" ) )

		for( j in 1:length( tiabs ) )
		{
            pmid <- doi <- year <- title <- url <- NA

			pmid <- tiabs[[ j ]]$pmid
			doi <- tiabs[[ j ]]$doi
			year <- tiabs[[ j ]]$year
			title <- paste( tiabs[[ j ]]$title, collapse = " " )
            url <- paste0( 'https://doi.org/', doi )


			if( is.list( doi ) )
				doi <- NA
            
            if( is.list( pmid ) ){ pmid <- NA }
            if( is.list( year ) ){ year <- NA }            
            if( is.list( title ) ){ title <- NA }            


            skip <- FALSE
            if( is.na( pmid ) ){ skip <- TRUE }
            if( is.na( doi ) ){ skip <- TRUE }            
            if( is.na( year ) ){ skip <- TRUE }            
            if( is.na( title ) ){ skip <- TRUE }            

            if( ! skip ) {
                single <- data.frame( pmid = pmid, doi = doi, url = url, year = year, title = title )
                all <- rbind( all, single )
            } else {
                print( paste0( "*** ERROR ***: could not parse: ", pmid ) )
            }
		}
		Sys.sleep( 2 )
	}

	return( all )
}


###################################
# END FUNCTIONS
###################################

# output directory
outdir <- 'out.dois'
dir.create( outdir, showWarnings = FALSE )

# get dois
df <- get_dois()

# write to csv
write.csv( df, file = paste0( outdir, '/dois.csv' ) ) 

# write url only to txt
urls <- df[, 'url' ]
write.table( urls, file = paste0( outdir, '/urls.txt' ), quote = FALSE, row.names = FALSE, col.names = FALSE ) 

