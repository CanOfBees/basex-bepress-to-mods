module namespace to-mods = "http://cob.net/to-mods";

import module namespace functx = "http://www.functx.com";
(: namespaces :)
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace etd = "http://www.ndltd.org/standards/etdms/1.1";
declare namespace bp = "http://www.bepress.com/products/digital-commons";

(: variables :)
declare variable $to-mods:c-date := fn:format-dateTime(fn:current-dateTime(), '[Y]-[M,2]-[D,2]T[H]:[m]:[s][Z]');

(:~
 : dispatch function for recursively processing and converting bepress metadata.xml to MODS xml
 :
 : @param nodes
 :)
declare function to-mods:dispatch( $nodes as node()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      (: case text() return fn:normalize-space($node) :)
      case element(documents) return to-mods:passthru($node)
      case element(document) return to-mods:document($node)
      case element(submission-path) return to-mods:submission-path($node)
      case element(authors) return to-mods:passthru($node)
      case element(author) return to-mods:author($node)
      case element(fields) return to-mods:passthru($node)
      case element(field) return (
        if ($node/@name = 'advisor1') then to-mods:advisor($node) else
        if ($node/@name = 'advisor2') then to-mods:committee-mem($node) else ()
      )
      case element(title) return to-mods:title($node)
      case element(disciplines) return to-mods:passthru($node)
      case element(discipline) return to-mods:discipline($node)
      case element(abstract) return to-mods:abstract($node)
      (:case element(publication-date) return to-mods:pub-date($node)
      case element(submission-date) return to-mods:sub-date($node):)


      default return to-mods:passthru($node)
};

(:~
 : passthru function 
 :)
declare function to-mods:passthru( $node as node()* ) as item()* {
  to-mods:dispatch($node/node())
};

(:~
 : begin the MODS serialization process
 : @param $node processes the 'document' node
 :)
declare function to-mods:document( $node as node()* ) as item()* {
  <mods:mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3" version="3.5" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:etd="http://www.ndltd.org/standards/etdms/1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
    {to-mods:dispatch($node/node())}
    <mods:originInfo>
      {to-mods:sub-date($node)}
      {to-mods:pub-date($node)}
    </mods:originInfo>
    <mods:typeOfResource>text</mods:typeOfResource>
    {to-mods:extension($node)}
  </mods:mods>
};

(: convert bp:submission-path to mods:identifier :)
declare function to-mods:submission-path( $node as node()* ) as item()* {
  <mods:identifier type="local">{$node/node()}</mods:identifier>
};

(: convert bp:author(s) to mods:name[roleTerm='Author'] :)
declare function to-mods:author( $node as node()* ) as element()* {
  <mods:name>
    <mods:namePart type="given">{$node/fname/text()}</mods:namePart>
    <mods:namePart type="family">{$node/lname/text()}</mods:namePart>
    {if ($node/terms) then <mods:namePart type="terms of address">{$node/terms/text()}</mods:namePart> else ()}
    <mods:role>
      <mods:roleTerm type="text" authority="marcrelator" valueURI="http://id.loc.gov/vocbulary/relators/aut">Author</mods:roleTerm>
    </mods:role>
  </mods:name>
};

declare function to-mods:advisor( $node as node()* ) as element()* {
  <mods:name>
    <mods:displayForm>{$node/value/text()}</mods:displayForm>
    <mods:role>
      <mods:roleTerm type="text" authority="marcrelator" valueURI="http://id.loc.gov/vocabulary/relators/ths">Thesis advisor</mods:roleTerm>
    </mods:role>
  </mods:name>
};

declare function to-mods:committee-mem( $node as node()* ) as element()* {
  for $mems in $node/value
  let $mem := fn:tokenize($mems, ',')
  return
    <mods:name>
      <mods:displayForm>{$mem}</mods:displayForm>
      <mods:role>
        <mods:roleTerm authority="local">Committee member</mods:roleTerm>
      </mods:role>
    </mods:name>
};

declare function to-mods:title( $node as node()* ) as element()* {
  <mods:titleInfo>
    <mods:title>{$node/data()}</mods:title>
  </mods:titleInfo>
};

declare function to-mods:discipline( $node as node()* ) as element()* {
  <mods:subject><mods:topic>{$node/data()}</mods:topic></mods:subject>
};

declare function to-mods:abstract( $node as node()* ) as element()* {
  <mods:abstract>{$node/data()}</mods:abstract>
};

declare function to-mods:pub-date( $node as node()* ) as element()* {
  <mods:dateIssued keyDate="yes" encoding="edtf">{functx:substring-before-match($node/publication-date/text(), '-[0-9]{2}T')}</mods:dateIssued>
};

declare function to-mods:sub-date( $node as node()* ) as element()* {
  <mods:dateCreated encoding="w3cdtf">{$node/submission-date/text()}</mods:dateCreated>
};

declare function to-mods:extension( $node as node()* ) as element()* {
  let $degree-name := $node/fields/field[@name='degree_name']/value/text()
  let $dept-name := $node/fields/field[@name='department']/value/text()
  return
    if (fn:starts-with($node/submission-path/text(), 'utk_grad'))
    then (
      <mods:extension>
        <etd:degree>
          <etd:name>{$degree-name}</etd:name>
          <etd:discipline>{$dept-name}</etd:discipline>
          <etd:grantor>University of Tennessee</etd:grantor>
        </etd:degree>
      </mods:extension>,
      <mods:genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2014026039">Academic theses</mods:genre>
    ) else ()
};