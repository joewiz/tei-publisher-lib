xquery version "3.1";

module namespace ted="http://existsolutions.com/apps/tei-publisher-lib/ts-ext-docx";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace tf="http://existsolutions.com/xquery/functions/tei";

import module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/docx" at "../content/ext-docx.xql";

declare variable $ted:CFG := map { };

(:~ Text shapes the docx post-processing has to carry through unchanged.

    A Word document's run text is plain text: whatever angle brackets it contains
    were typed by an author and are escaped in word/document.xml like any other
    character. They are not markup and nothing downstream may treat them as such.

    These come from FRUS annotation sheets, where a compiler encodes an en dash as
    "<n>" and an em dash as "<m>" for the typesetter to resolve. One chapter alone
    carries 811 of them. :)
declare variable $ted:ANGLE-CODES :=
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <text>
            <body>
                <p>Foreign Relations, 1981&lt;n&gt;1988</p>
                <p>Electronic Telegrams, D830012&lt;n&gt;0076.</p>
                <p><hi rend="strikethrough">a code &lt;m&gt; here</hi></p>
                <p>an unpaired bracket: a &lt; b</p>
                <p>two codes in one node: 1981&lt;n&gt;1988 and 1977&lt;m&gt;1980</p>
            </body>
        </text>
    </TEI>;

declare
  %test:assertTrue
function ted:finish-wraps-headings-into-divs() as xs:boolean {
  let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <text><body>
                  <head xmlns:tf="http://existsolutions.com/xquery/functions/tei" tf:level="1">H1</head>
                  <p>Para</p>
                  <head xmlns:tf="http://existsolutions.com/xquery/functions/tei" tf:level="1">H2</head>
                  <p>Q</p>
                </body></text>
              </TEI>
  let $res := pmf:finish($ted:CFG, $tei)
  return count($res//tei:div) = 2
};

declare
  %test:assertTrue
function ted:finish-heads-stripped-level() as xs:boolean {
  let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <text><body>
                  <head xmlns:tf="http://existsolutions.com/xquery/functions/tei" tf:level="1">H1</head>
                  <p>Para</p>
                  <head xmlns:tf="http://existsolutions.com/xquery/functions/tei" tf:level="1">H2</head>
                  <p>Q</p>
                </body></text>
              </TEI>
  let $res := pmf:finish($ted:CFG, $tei)
  return every $h in $res//tei:div/tei:head satisfies empty($h/@tf:level)
};

declare
  %test:assertTrue
function ted:finish-returns-unchanged-without-head() as xs:boolean {
  let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0"><text><body><p>x</p></body></text></TEI>
  let $res := pmf:finish($ted:CFG, $tei)
  return deep-equal($res, $tei)
};
