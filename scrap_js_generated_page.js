// scrape_techstars.js

var webPage = require('webpage');
var page = webPage.create();
var args = require('system').args;
var fs = require('fs');
var id = args[1];

var URLs = ['http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/1990-decretos-1',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/1995',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/1999-decretos-2',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2003',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2007',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2011-decretos-2',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2015-decretos-1',
            'http://www4.planalto.gov.br/legislacao/portal-legis/legislacao-1/decretos1/2019-decretos']
var filename = ['1990.html', '1995.html', '1999.html', '2003.html', '2007.html', '2011.html', '2015.html', '2019.html']

function savePage(id) {
  page.open(URLs[id], function(status) {
    // Mesmo os codigos para raspar paginas geradas por JavaScript nao estavam funcionando para as paginas de decretos do site
    // do planalto. O segredo foi usar esse onLoadFInished.
    page.onLoadFinished = function(status){
      var content = page.content;
      fs.write(filename[id], content, 'w');
      phantom.exit();
    };
  });
}

savePage(id);
