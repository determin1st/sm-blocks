<?php
/**
* demo-shop template
*/
defined('ABSPATH') || exit();
get_header('shop');
# configuration
# {{{
# products grid
$og = json_encode([
  ##
  "size"        => 8,
  "columns"     => 4,
  "columnsMin"  => 2,
  "order"       => "default",
  ##
  "maxX" => 288,
  "maxY" => 400,
  "fontSize" => 24,
  "itemSizeBalance" => "55:17:28",
  ##
  "itemImage"    => true,
  "itemIcon"     => false,
  "itemFeatures" => false,
  "itemPrice"    => true,
  "itemControls" => true,
]);
# paginator
$op = json_encode([
  "rangeMode" => 2,
  #"rangePlus"  => 2,
  #"rangeMinus" => 2,
]);
# orderer
$oo = json_encode([
  "switchMode" => 1,
]);
# price filter
$opf = json_encode([
  "sectionMode" => 1|2|4|16|32,
]);
# page title
$o = substr(get_locale(), 0, 2) === 'en'
  ? 'test version'
  : 'версия для тестирования';
# }}}
# generate content
$o = <<<EOD

<div id="sm-demo">
  <div class="a">
    <!-- wp:sm-blocks/price-filter {$opf} /-->
    <!-- wp:sm-blocks/category-filter /-->
    <!-- :sm-blocks/category-filter {"hasEmpty":true,"baseCategory":"санки"} /-->
    <!-- :sm-blocks/category-filter {"hasEmpty":true,"baseCategory":"инвентарь"} /-->
  </div>
  <div class="b">
    <h3>{$o}</h3>
    <div class="c">
      <!-- wp:sm-blocks/paginator {$op} /-->
      <!-- wp:sm-blocks/orderer {$oo} /-->
    </div>
    <!-- wp:sm-blocks/grid {$og} /-->
  </div>
</div>

EOD;
# output
echo apply_filters('the_content', $o);
# done
get_footer('shop');
?>
