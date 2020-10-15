<?php
/**
* demo-shop template
*/
defined('ABSPATH') || exit();
get_header('shop');
# initial state
$og  = json_encode([ # products grid {{{
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
# }}}
$oo  = json_encode([ # orderer {{{
  "switchMode" => 1,
]);
# }}}
$opf = json_encode([ # price filter {{{
  'sectionMode' => 1|2|4|8|16,
]);
# }}}
$ocf = json_encode([ # category filter {{{
  #'baseCategory' => '16',
  #'baseCategory' => '37',
  #'operator'     => 'AND',
  'hasEmpty'     => true,
  'hasCount'     => true,
]);
# }}}
# page title
$title = substr(get_locale(), 0, 2) === 'en'
  ? 'test version'
  : 'версия для тестирования';
# generate markup
$o = <<<EOD

<div id="sm-demo">
  <div class="a">
    <!-- wp:sm-blocks/price-filter {$opf} /-->
    <!-- wp:sm-blocks/category-filter {$ocf} /-->
    <!-- :sm-blocks/category-filter {"baseCategory":"37"} /-->
  </div>
  <div class="b sm-blocks-resizer">
    <h3>{$title}</h3>
    <div class="c sm-blocks-resizer">
      <!-- wp:sm-blocks/paginator {
        "gotoMode":3
      } /-->
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
