#!/home1/wim/R-3.6.1/bin/Rscript --no-save --no-restore

# Rename CDXXXXX.rm5 files to corresponding .pub version.
#########################################################

library( 'stringr' )

#######################
# FUNCTIONS
#######################

###
# Move file
##
move_file <- function( src, des )
{
	if( file.exists( src ) ) 
	{
		print( paste0( "*** Moving: ", src, ' to ', des ) )
		file.copy( src, des )
		if( file.exists( des ) ){ unlink( src ) }
	}
}

###
# Return CD and pub of given url
##
get_urls <- function( infile )
{

	# read urls used to download rm5 files
	urls_raw <- read.table( infile )

	# split urls on '.'
	urls <- data.frame( stringr::str_split_fixed( urls_raw$V1, '\\.', 5 ) )
	urls <- urls[ , c( 'X4', 'X5' ) ]
	colnames( urls ) <- c( 'CD', 'pub' )

	return( urls )
}

###
# Get rm5 files
##
get_rm5s <- function( download_folder )
{
	infiles <- dir( download_folder )
	rm5_files <- infiles[ grep( '.rm5', infiles ) ]

	id <- gsub( 'StatsDataOnly', '', rm5_files )
	id <- gsub( '.rm5', '', id )
	id <- gsub( '\\)', '', id )

	ids <- data.frame( stringr::str_split_fixed( id, ' \\(', 2 ) )
	ids$rm5_file <- paste0( download_folder, '/', rm5_files )
	colnames( ids ) <- c( 'CD', 'version', 'rm5_file' )
	return( ids )
}

#######################
# END FUNCTIONS
#######################

# location of urls and Downloaded rm5 folder
urls_file <- 'urls.txt'
download_folder <- 'Downloads'
outdir <- 'renamed'

# create outdir
dir.create( outdir, showWarnings = FALSE )

# get converted urls (CD, pub)
urls <- get_urls( 'urls.txt' )

# get list of downloaded rm5
rm5s <- get_rm5s( download_folder )

# merge urls and downloaded files
df <- merge( rm5s, urls )

# relabel
df$outfile <- gsub( '\\.\\.', '\\.', paste0( outdir, '/', df$CD, '.', df$pub, '.rm5' ) )
df$seq <- gsub( 'pub', '', df$pub )
df$pub <- NULL

# Sort CD (1) and wihtin that (seq)
df <- df[ with( df, order( CD, seq ) ), ]

# get CD ids for multiple versions
ids_multiple <- df[ grep( ' \\(', df$rm5_file ), 'CD' ]

# get all CDs with a single file
df_single <- df[ !df$CD %in% ids_multiple, ]

if( nrow( df_single ) > 0 )
{
	# write single CSs to destination
	for( i in 1:nrow( df_single ) )
	{
		src <- df_single[ i, 'rm5_file' ]
		des <- df_single[ i, 'outfile' ]

		# move file
		move_file( src, des )
	}
}

# get all CDs with multiple versions
df_multiple <- df[ df$CD %in% ids_multiple, ]

cds <- unique( df_multiple$CD )

for( CD in cds )
{
	sub <- df_multiple[ df_multiple$CD == CD, ]

	idx <- grep( " \\(2", sub$rm5_file )
	if( length( idx ) > 1 )
	{
		print( sub )
		src <- sub[ max( idx ), 'rm5_file' ]
		des <- sub[ max( idx ), 'outfile'  ]

		# remove hightest pub-version
		seq <- sub[ max( idx ), 'seq'  ]
		sub <- sub[ sub$seq != seq, ]

		move_file( src, des )
	}

	idx <- grep( " \\(1", sub$rm5_file )
	if( length( idx ) > 1 )
	{
		print( sub )
		src <- sub[ max( idx ), 'rm5_file' ]
		des <- sub[ max( idx ), 'outfile'  ]
		move_file( src, des )
	}
}





