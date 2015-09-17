<?php
set_include_path(get_include_path() . PATH_SEPARATOR . '../scraperwiki-php/');

require 'scraperwiki.php';

date_default_timezone_set('Australia/Hobart');

require 'simple_html_dom.php';

$url = 'http://www.huonvalley.tas.gov.au/services/planning-2/planningnotices/';

$dapage = $url;
$html = scraperwiki::scrape($dapage);
$dom = new simple_html_dom();
$dom->load($html);
$darow = $dom->find("/html/body/div/main/table/tbody/tr");
print 'number of records: ' . sizeof($darow);
foreach ($darow as $thisrow) {
    //<tr>
    //	<td>DA-6-2015 - Dwelling and Carport - Land - (CT128515-1) directly to the south of 14 Smyley Street, Franklin</td>
    //    <td>Smyley Street, Franklin, Tasmania, Australia</td>
    //	  <td>15 Sep 2015</td>
    //    <td>29 Sep 2015</td>
    //    <td>
    //		<a class="btn-sm btn btn-primary" href="https://drive.google.com/open?id=0B4M5kQr8ve_Gamx2dmtLbjZmY28" style="margin-bottom: 3px; margin-right: 3px;">Copy of Plans for display	</a>                                
    //	</td>
    //</tr>
    $record = array();
    $cells = $thisrow->find("td");
//Although this specifies tbody is still returns the thead/tr row so I have to delete it
    if (sizeof($cells) > 0) {
        $refdesc = $cells[0]->plaintext;
        $delim = ' - ';
        $delimpos = stripos($refdesc, $delim);
        $record['council_reference'] = substr($refdesc, 0, $delimpos - 1);
        $record['description'] = substr($refdesc, $delimpos + strlen($delim));
        $record['address'] = $cells[1]->plaintext;
        $record['date_received'] = date('Y-m-d', strtotime($cells[2]->plaintext));
        $record['on_notice_to'] = date('Y-m-d', strtotime($cells[3]->plaintext));
        $record['info_url'] = $cells[4]->find('a')[0]->href;
        $record['comment_url'] = 'http://www.huonvalley.tas.gov.au/services/planning-2/how-to-make-a-representation/';
        $record['date_scraped'] = date('Y-m-d');
        scraperwiki::save_sqlite(array('council_reference'), $record, 'data');
    }
}
?>