import module namespace tm = "http://cob.net/to-mods" at "modules/to-mods.xq";
import module namespace tm2 = "http://cob.net/tm2" at "modules/tm2.xq";

for $doc in doc('sample-data-uris.xml')//@href/doc(.)
let $doc-path := replace(document-uri($doc), 'metadata.xml', '')
let $old-doc := tm:dispatch($doc, $doc-path)
(:let $new-doc := tm2:dispatch($doc):)
return(
  (:tm:dispatch($doc):)
  file:write($doc-path || 'MODS-tm.xml', $old-doc)
  (:file:write($doc-path || 'MODS-tm2.xml', $new-doc):)
)
