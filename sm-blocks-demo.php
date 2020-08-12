<?php
/**
* demo-shop template
*/
# standard guard
defined('ABSPATH') || exit();
# output header
get_header('shop');
# create block configuration
# products
$o = json_encode([
  ##
  ## grid
  ##
  "size"        => 8,
  "columns"     => 4,
  "columnsMin"  => 2,
  "order"       => "default",
  ##
  ## card (grid's element)
  ##
  "maxX" => 288,
  "maxY" => 400,
  "fontSize" => 24,
  "itemSizeBalance" => "55:17:28",
  ##
  ## inner blocks (card's elements)
  ##
  "itemImage"    => true,
  "itemIcon"     => false,
  "itemFeatures" => false,
  "itemPrice"    => true,
  "itemControls" => true,
]);
$po = json_encode([
  #"expansion"  => false,
  "expansion"  => true,
  #"rangePlus"  => 2,
  #"rangeMinus" => 2,
]);
$oo = json_encode([
  "switchMode" => 1,
]);
/***
$oo = '';
$i = -1;
while (++$i < 50)
{
  $j = rand(0, 2);
  $oo .= '<!-- wp:sm-blocks/orderer {"switchMode":"'.$j.'"} /-->';
}
/***/
# generate and output page content
$o = <<<EOD

  <div id="sm-demo">
    <div class="a">
      <!-- wp:sm-blocks/category-filter /-->
      <!-- :sm-blocks/category-filter {"hasEmpty":true,"baseCategory":"санки"} /-->
      <!-- :sm-blocks/category-filter {"hasEmpty":true,"baseCategory":"инвентарь"} /-->
    </div>
    <div class="b">
      <div class="c">
        <!-- wp:sm-blocks/paginator {$po} /-->
        <!-- wp:sm-blocks/orderer {$oo} /-->
      </div>
      <!-- wp:sm-blocks/products {$o} /-->
    </div>
  </div>

EOD;
echo apply_filters('the_content', $o);
# output footer
get_footer('shop');
# done
?>
