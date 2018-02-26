import module namespace tm = "http://cob.net/to-mods" at "modules/to-mods.xq";

for $doc in doc('sample-data-uris.xml')//@href/doc(.)
let $doc-path := replace(document-uri($doc), 'metadata.xml', '')
let $new-doc := tm:dispatch($doc, $doc-path)

return(
  file:write($doc-path || 'MODS.xml', $new-doc)
)
