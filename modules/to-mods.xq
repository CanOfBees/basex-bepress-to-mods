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
declare function to-mods:dispatch(
  $nodes as node()*,
  $path as item()?
) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      (: case text() return fn:normalize-space($node) :)
      case element(documents) return to-mods:passthru($node, $path)
      case element(document) return to-mods:document($node, $path)
      case element(submission-path) return to-mods:submission-path($node)
      case element(authors) return to-mods:passthru($node, $path)
      case element(author) return to-mods:author($node)
      case element(fields) return to-mods:passthru($node, $path)
      case element(field) return (
        if ($node/@name = 'advisor1') then to-mods:advisor($node) else
        if ($node/@name = 'advisor2') then to-mods:committee-mem($node) else ()
      )
      case element(title) return to-mods:title($node)
      case element(disciplines) return to-mods:passthru($node, $path)
      case element(discipline) return to-mods:discipline($node)
      case element(abstract) return to-mods:abstract($node)

      default return to-mods:passthru($node, $path)
};

(:~
 : passthru function 
 :)
declare function to-mods:passthru(
  $node as node()*,
  $path as item()?
) as item()* {
  to-mods:dispatch($node/node(), $path)
};

(:~
 : begin the MODS serialization process
 : @param $node processes the 'document' node
 :)
declare function to-mods:document(
  $node as node()*,
  $path as item()?
) as item()* {
  <mods:mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3" version="3.5" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:etd="http://www.ndltd.org/standards/etdms/1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
    {to-mods:dispatch($node/node(), $path)}
    <mods:originInfo>
      {to-mods:sub-date($node)}
      {to-mods:pub-date($node)}
    </mods:originInfo>
    <mods:typeOfResource>text</mods:typeOfResource>
    {to-mods:extension($node)}
    {to-mods:genre($node)}
    {to-mods:series($node)}
    {to-mods:keywords($node)}
    {to-mods:comments($node)}
    {to-mods:access-condition($node)}
    {to-mods:related-items($node, $path)}
    {to-mods:record-info($node)}
    {to-mods:withdrawn($node)}
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

declare function to-mods:genre( $node as node()* ) as element()* {
  let $title := $node/publication-title/text()
  return
    if (matches($title, 'Doctoral Dissertations'))
    then (
      <mods:genre authority="coar" valueURI="http://purl.org/coar/resource_type/c_db06">doctoral thesis</mods:genre>
    ) else if (matches($title, 'Masters Theses'))
      then (
        <mods:genre authority="coar" valueURI="http://purl.org/coar/resource_type/c_bdcc">masters thesis</mods:genre>
      ) else ()
};

declare function to-mods:keywords( $node as node()* ) as element()* {
  <mods:note displayLabel="Keywords submitted by author">{fn:string-join( ($node/keywords//keyword/text()), ', ')}</mods:note>
};

declare function to-mods:comments( $node as node()* ) as element()* {
  if ($node/fields/field[@name='comments'])
  then (
    <mods:note displayLabel="Submitted Comment">{$node/fields/field[@name='comments']/value/text()}</mods:note>
  ) else ()
};

declare function to-mods:access-condition( $node as node()* ) as element()* {
  let $embargo-xsdate := if ($node/fields/field[@name='embargo_date'])
                         then (xs:dateTime($node/fields/field[@name='embargo_date']/value/text()))
                         else ()
  let $pub-xsdate := xs:dateTime($node/publication-date/text())
  return
    if (
      ($embargo-xsdate <= $pub-xsdate) or
      ($embargo-xsdate = xs:dateTime('2011-12-01T00:00:00-08:00')) or
      ($embargo-xsdate = xs:dateTime('2011-12-01T00:00:00-08:00')) or
      (fn:not(xs:string($embargo-xsdate)))
    ) then ()
    else if (($embargo-xsdate > $pub-xsdate) and ($embargo-xsdate < xs:dateTime($to-mods:c-date)))
    then (
        <mods:note displayLabel="Historical embargo date">{$embargo-xsdate}</mods:note>
    ) else (
        <mods:accessCondition type="restriction on access">{"This item may not be viewed until: " || $embargo-xsdate}</mods:accessCondition>
    )
};

declare function to-mods:series( $node as node()* ) as element()* {
  <mods:relatedItem type="series">
    <mods:titleInfo lang="eng">
      <mods:title>Graduate Theses and Dissertations</mods:title>
    </mods:titleInfo>
  </mods:relatedItem>
};

declare function to-mods:related-items(
  $node as node()*,
  $path as item()?
) as element()* {
  let $suppl-archive-name := $node/supplemental-files/file/archive-name/text()
  let $file-list := file:list($path)
  for $file in functx:sort($file-list)
  let $f := if (fn:matches($file, '^\d{1,}-'))
             then (fn:replace($file, '^\d{1,}-', ''))
             else ()
  where ($f = ($suppl-archive-name))
  count $count
  return (
    <mods:relatedItem type="constituent">
      <mods:titleInfo><mods:title>{$f}</mods:title></mods:titleInfo>
      <mods:physicalDescription>
        <mods:internetMediaType>
          {if ($suppl-archive-name)
           then ($node/supplemental-files/file/archive-name[. = $f]/following-sibling::mime-type/text())
           else (fetch:content-type($path || $f))}
        </mods:internetMediaType>
        {if ($node/supplemental-files/file/archive-name[. = $f]/following-sibling::description)
         then (
            <mods:abstract>{$node/supplemental-files/file/archive-name[. = $f]/following-sibling::description/text()}</mods:abstract>
          ) else ()}
      </mods:physicalDescription>
      <mods:note displayLabel="supplemental_file">{"SUPPL_" || $count}</mods:note>
    </mods:relatedItem>
  )
};

declare function to-mods:record-info( $node as node()* ) as element()* {
  <mods:recordInfo displayLabel="Submission">
    <mods:recordCreationDate encoding="w3cdtf">{$node/submission-date/text()}</mods:recordCreationDate>
    <mods:recordContentSource>University of Tennessee, Knoxville Libraries</mods:recordContentSource>
    <mods:recordOrigin>Converted from bepress XML to MODS v3.5 in general compliance with the MODS Guidelines (Version 3.5).</mods:recordOrigin>
    <mods:recordChangeDate encoding="w3cdtf">{$to-mods:c-date}</mods:recordChangeDate>
  </mods:recordInfo>
};

declare function to-mods:withdrawn( $node as node()* ) as element()* {
  if ($node/withdrawn/text())
  then (
    <mods:recordInfo displayLabel="Withdrawn">
      <mods:recordChangeDate keyDate="yes">{$node/withdrawn/text()}</mods:recordChangeDate>
    </mods:recordInfo>
  ) else ()
};