(:~
 : User: bridger
 : Date: 11/7/17
 : Time: 9:29 PM
 :
 :)

(: namespaces :)
module namespace to-mods = "to-mods";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace bp = "http://www.bepress.com/products/digital-commons";

(: imports :)
import module namespace esc = "http://cob.net/ns/esc" at "modules/escape.xqm";

(: primary function :)
declare function to-mods:dispatch( $nodes as node()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case text() return $node
      case element(bp:documents) return to-mods:pass($node)
      case element(bp:document) return to-mods:mods($node)
      case element(bp:submission-path) return to-mods:identifier($node)
      case element(bp:authors) return to-mods:pass($node)
      case element(bp:author) return to-mods:au-name($node)

      default return to-mods:pass($node)
};

(: passthru function :)
declare function to-mods:pass( $nodes as node()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case element(bp:documents) return to-mods:pass($node/node())
      case element(bp:authors) return to-mods:pass($node/node())
      default return to-mods:dispatch($node/node())
};

(: start our new MODS record serialization :)
declare function to-mods:mods( $node as node()* ) as item()* {
  <mods:mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3" version="3.5"
  xmlns:xlink="http://www.w3c.org/1999/xlink" xmlns:etd="http://www.ndltd.org/standards/etdms/1.1"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
    {to-mods:dispatch($node/node())}
  </mods:mods>
};

(: mods:identifier[@type='local'] :)
declare function to-mods:identifier( $node as node()* ) as item()* {
  <mods:identifier type="local">{to-mods:dispatch($node/node())}</mods:identifier>
};

(: mods:name :)
declare function to-mods:au-name( $node as node()* ) as item()* {
  let $au-name-fam := $node/bp:lname/text()
  let $au-name-giv := if ($node/bp:mname)
                    then ($node/bp:fname/text() || ' ' || $node/bp:mname/text())
                    else ($node/bp:fname/text())
  let $au-name-suf := $node/bp:suffix/text()
  return
    <mods:name>
      <mods:namePart type="family">{$au-name-fam}</mods:namePart>
      <mods:namePart type="given">{$au-name-giv}</mods:namePart>
      {if ($au-name-suf)
       then <mods:namePart type="termsOfAddress">{$au-name-suf}</mods:namePart>
       else ()}
      <mods:role>
        <mods:roleTerm authority="marcrelator" valueURI="http://id.loc.gov/vocabulary/relators/aut">Author</mods:roleTerm>
      </mods:role>
    </mods:name>
};