// scrape_techstars.js

var webPage = require('webpage');
var page = webPage.create();
var args = require('system').args;
var fs = require('fs');
var url = args[1];
var filename = args[2];

function savePage(url, filename) {
  page.open(url, function(status) {
    // Mesmo os codigos para raspar paginas geradas por JavaScript nao estavam funcionando para as paginas de decretos do site
    // do planalto. O segredo foi usar esse onLoadFInished.
    page.onLoadFinished = function(status){
      var content = page.content;
      fs.write(filename, content, 'w');
      phantom.exit();
    };
  });
}

savePage(url, filename);
