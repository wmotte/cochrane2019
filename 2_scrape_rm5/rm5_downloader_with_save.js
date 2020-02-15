// *****************************************************************************
// Run: /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome
// --remote-debugging-port=9222 --no-first-run --no-default-browser-check
// --user-data-dir=$(mktemp -d -t 'chrome-remote_data_dir')
// *****************************************************************************
'use strict';

// import libraries
const puppeteer = require( 'puppeteer' );
const cdFinder = require( 'fs-finder' );
const fs = require( 'fs' );

//##############################################################################
// FUNCTIONS
//##############################################################################

/**
 * Get output file name.
 */
function getOutputFileName( pageUrl ) {

  var outFile = "";

  // get outFile
  if( pageUrl.indexOf( 'pub' ) == -1 ) {
    var outPub = 'pub0'; // if no .pub exist
    var outName = pageUrl.split(".").reverse()[ 0 ]; // e.g. ''ÇD010678'
    outFile = outName.concat( "." ).concat( outPub ).concat( ".rm5" ); // e.g. 'CD010678.pub3.rm5'
  } else {
    var outPub = pageUrl.split(".").reverse()[ 0 ]; // e.g. 'pub3'
    var outName = pageUrl.split(".").reverse()[ 1 ]; // e.g. ''ÇD010678'
    outFile = outName.concat( "." ).concat( outPub ).concat( ".rm5" ); // e.g. 'CD010678.pub3.rm5'
  }
  return( outFile );
}

/**
 * Scrawl to end of page
 */
async function scrollToBottom( page ) {
  const distance = 800; // should be less than or equal to window.innerHeight
  const delay = 100;
  while (await page.evaluate(() => document.scrollingElement.scrollTop + window.innerHeight < document.scrollingElement.scrollHeight)) {
    await page.evaluate((y) => { document.scrollingElement.scrollBy(0, y); }, distance);
    await page.waitFor(delay);
  }
}

//##############################################################################
// END FUNCTIONS
//##############################################################################

// define download directory (change!)
let downloadDir = '/Users/wimotte/Downloads';

// get pageUrl
//let pageUrl = process.argv[ 2 ];
let pageUrl = 'https://www.cochranelibrary.com/cdsr/doi/10.1002/14651858.CD010678.pub3';

// check pageUrl
if( ! pageUrl ) { throw "Please provide an URL as the first argument"; }

// get getOutputFileName
var outDir = '/Users/wimotte/Desktop/scihub/out.cds';

// create output directory of not yet present
! fs.existsSync( outDir ) && fs.mkdirSync( outDir );

// get full path output file
var outFile = outDir.concat( "/" ).concat( getOutputFileName( pageUrl ) );
console.log( 'Output file: '.concat( outFile ) );


/**
 * Run Puppet function
 */
( async() => {

	try {
    const browser = await puppeteer.connect({browserURL: 'http://localhost:9222'});
    const page = await browser.newPage();

      //await page.setRequestInterception( false );
      page.setViewport( { width: 1024, height: 1024 } );
      await page.goto( pageUrl, { waitUntil: 'networkidle0' } );
  		await page.waitFor( 2000 );

      // set cookies
      try{
        await page.click( "#js-cookie-message > div > div > div.system-message-description > a" );
      } catch( err ) { console.log( "Cookies already set! " + err ); }

  	   await page.waitFor( 1500 );

       // scrawl to buttom of page
       await scrollToBottom( page );

       let selectorValue = '';
       let selectorValue7 = '#cdsr-nav > nav > ul:nth-child(7) > li.cdsr-nav-link.download-stats-data-link';
       let selectorValue8 = '#cdsr-nav > nav > ul:nth-child(8) > li.cdsr-nav-link.download-stats-data-link';
       let selectorValue9 = '#cdsr-nav > nav > ul:nth-child(9) > li.cdsr-nav-link.download-stats-data-link';
       let selectorValue10 = '#cdsr-nav > nav > ul:nth-child(10) > li.cdsr-nav-link.download-stats-data-link';
       let selectorValue11 = '#cdsr-nav > nav > ul:nth-child(11) > li.cdsr-nav-link.download-stats-data-link';
       let selectorValue12 = '#cdsr-nav > nav > ul:nth-child(12) > li.cdsr-nav-link.download-stats-data-link';

       if (( await page.$( selectorValue7 ) ) !== null) { selectorValue = selectorValue7; }
       if (( await page.$( selectorValue8 ) ) !== null) { selectorValue = selectorValue8; }
       if (( await page.$( selectorValue9 ) ) !== null) { selectorValue = selectorValue9; }
       if (( await page.$( selectorValue10 ) ) !== null) { selectorValue = selectorValue10; }
       if (( await page.$( selectorValue11 ) ) !== null) { selectorValue = selectorValue11; }
       if (( await page.$( selectorValue12 ) ) !== null) { selectorValue = selectorValue12; }

      // click on 'Download statistics'
      try{
        await page.click( selectorValue );
      } catch( err ) { console.log( "No Download statististics button! " + err ); }

      // set 'I agree to these terms' and check for status
      try{
        let checkbox = await page.$('body > div.site-container > div.scolaris-modal.open > div.scolaris-modal-content.clearfix > div > div > form > p > input' );
        await checkbox.click();
      } catch( err ) { console.log( "No checkbox to set! " + err ); }

  		console.log( "Passed the checkbox" )
  		await page.waitFor( 1500 );

  		// click 'Download data'
      try{
  			await page.click( 'body > div.site-container > div.scolaris-modal.open > div.scolaris-modal-content.clearfix > div > div > form > p > button > i' );
  			await page.waitFor( 2500 );
      } catch( err ) { console.log( "No final Download data button! " + err ); }

      /**
       * Asynchronous renaming of downloaded CD rm5 file.
       */
      await cdFinder.in( downloadDir ).findFiles( '*.rm5', function( files ) {

          if( files.length > 0 )
          {
            var cdfile = files[ 0 ];
            fs.rename( cdfile, outFile, ( err ) => {
              if( err ) throw err;
              else console.log( 'Successfully moved' );
            });
          }
      });

  	  await page.waitFor( 2000 );
  		await page.close();
      await browser.close();
      //await sleep( 2000 );
      //process.exit( 1 );

  } catch( err )
  { "*** ERROR ***" + console.log( err ) }
} )();
