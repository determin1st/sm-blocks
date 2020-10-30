<?php
/**
* demo-shop template
*/
defined('ABSPATH') || exit();
get_header('shop');
# initial state
$og  = json_encode([ # products grid {{{
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
# generate markup
$o = <<<EOD

<div id="sm-demo">
  <div class="a">
    <!-- wp:sm-blocks/price-filter {$opf} /-->
    <!-- wp:sm-blocks/category-filter {$ocf} /-->
    <!-- :sm-blocks/category-filter {"baseCategory":"37"} /-->
  </div>
  <div class="b sm-blocks-resizer">
    <div class="a">
      <h3>sm-blocks</h3>
    </div>
    <div class="b"><hr /></div>
    <div class="c">
      <!-- wp:sm-blocks/paginator {"gotoMode":3} /-->
      <!-- wp:sm-blocks/orderer {$oo} /-->
    </div>
    <div class="b"><hr /></div>
    <!-- wp:sm-blocks/products {

      "layout":"4:2:1:0"

    } /-->
  </div>
</div>

EOD;
# output
echo apply_filters('the_content', $o);
# done
get_footer('shop');
?>
