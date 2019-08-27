#!/home1/wim/R-3.6.1/bin/Rscript --no-save --no-restore

library( "stringr" )
library( 'pwr' )


###############################################################

###
# Calculate power for individual study based on population (~=meta) effect size.
##
get.power <- function( study.n1, study.n2, measure, meta.n1, meta.e1, meta.n2, meta.e2, effect.size, type = NA )
{
	if( is.na( study.n1 ) | is.na( study.n2 ) )
		return( data.frame( d = NA, power = NA ) ) 

	if( study.n1 < 3 | study.n2 < 3 )
		return( data.frame( d = NA, power = NA ) ) 

	if( type == 'CONT' )
	{
		if( measure == 'MD' )
		{
			# return NA as data is not normalized/standardized and aggregate SD is not available in rm5-files.
			return( data.frame( d = NA, power = NA ) ) 
		}

		if( measure == 'SMD' )
		{
			est <- pwr::pwr.t2n.test( d = effect.size, n1 = study.n1, n2 = study.n2, sig.level = 0.05, alternative = "two.sided" )
			return( data.frame( d = effect.size, power = est$power ) ) 
		}
	}

	if( type == 'DICH' )
	{
		if( measure[ 1 ] == 'OR' | measure[ 1 ] == 'PETO_OR' | measure[ 1 ] == 'RR' | measure[ 1 ] == 'RD' )
		{
			# Cohen's h, two different sample sizes
			h <- pwr::ES.h( meta.e1 / meta.n1, meta.e2 / meta.n2 )
			est <- pwr.2p2n.test( h = h, n1 = study.n1, n2 = study.n2, sig.level = 0.05, alternative = "two.sided" )

			return( data.frame( d = h, power = est$power ) ) 
		}
	}
} 

###
# Return power for all studies.
##
get.power.block <- function( data )
{
	data$power <- NA
	data$d <- NA

	for( r in 1:nrow( data ) )
	{
		d <- data[ r, ]
		est <- get.power( study.n1 = d$study_total_1, study.n2 = d$study_total_2, measure = d$effect_measure, 
								meta.n1 = d$total_1, meta.e1 = d$events_1, meta.n2 = d$total_2, meta.e2 = d$events_2, 
								effect.size = d$effect_size, type = d$type )

		data[ r, 'power' ] <- est$power
		data[ r, 'd' ] <- est$d
	}

	return( data )
}

###
# Get one systematic review.
##
get.data <- function( f )
{
	indir <- 'csvs/'
	infile <- paste( indir, '/', f, sep = '' )

	if( ! file.exists( infile ) )
	{
		return( NULL )
	}

	file <- try( read.csv( infile ) )
	if (class( file ) == "try-error" ) {
		cat( paste( cd, "\n", sep = '' ) )
		return( NULL )
	}	

	# read input
	d <- read.csv( infile )


	# empty file
	if( dim( d )[ 1 ] == 0 )
	{
		return( NULL )
	}

	# if no colnames( 'total_1'  or 'total_2' ) skip
	if( sum( colnames( d ) %in% c( 'total_1', 'total_2' ) ) != 2 )
	{
		return( NULL )
	}

	d$sample_size_per_group <- ( d$total_1 + d$total_2 ) / 2

	d$date <- as.Date( paste( "15jul", d$study_year, sep = '' ), "%d%B%Y" )

	# calculate power
	d <- get.power.block( d )

	return( d )
}

#############################################################

# create outdir
dir.create( 'combined', showWarnings = FALSE )

files <- dir( 'csvs' )
#files <- files[ grep( "CD", files ) ]

all1 <- all2 <- all3 <- all4 <- all5 <- all6 <- NULL

for( f in files[1:2000] ) { print( f ); study <- get.data( f ); all1 <- rbind( all1, study ) }
write.csv( all1, file = 'combined/all.1.csv' )

for( f in files[2001:4000] ) { print( f ); study <- get.data( f ); all2 <- rbind( all2, study ) }
write.csv( all2, file = 'combined/all.2.csv' )

for( f in files[4001:6000] ) { print( f ); study <- get.data( f ); all3 <- rbind( all3, study ) }
write.csv( all3, file = 'combined/all.3.csv' )

for( f in files[6001:8000] ) { print( f ); study <- get.data( f ); all4 <- rbind( all4, study ) }
write.csv( all4, file = 'combined/all.4.csv' )

for( f in files[8001:10000] ) { print( f ); study <- get.data( f ); all5 <- rbind( all5, study ) }
write.csv( all5, file = 'combined/all.5.csv' )

for( f in files[10001:13000] ) { print( f ); study <- get.data( f ); all6 <- rbind( all6, study ) }
write.csv( all6, file = 'combined/all.6.csv' )


# merge
all <- rbind( all1, all2, all3, all4, all5, all6 )
write.csv( all, file = 'combined/all.csv' )

test1 <- na.omit( all$study_id )
test2 <- na.omit( all$study_year )

plot( density( all$power, na.rm = TRUE ) )



