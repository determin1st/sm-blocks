<?php
/**
* demo-shop template
*/
defined('ABSPATH') || exit();
# initial state
# generate markup
$o = <<<EOD

<div id="sm-page">
  <div class="body">

    <div class="ctl">
      <div class="panel">
        <!-- :sm-blocks/panel-slider {} /-->
      </div>
      <div class="grid">
        <!-- wp:sm-blocks/paginator {"gotoMode":3} /-->
        <!-- wp:sm-blocks/rows-selector {} /-->
        <!-- wp:sm-blocks/orderer {
          "switchMode":1
        } /-->
      </div>
    </div>

    <div class="sep"><hr /></div>

    <div class="view">
      <div class="panel">
        <div class="content">
          <!-- wp:sm-blocks/price-filter {
          } /-->
          <!-- wp:sm-blocks/category-filter {

            "hasEmpty":true,
            "hasCount":true

          } /-->
          <!-- :sm-blocks/category-filter {"baseCategory":"37"} /-->
        </div>
      </div>
      <!-- wp:sm-blocks/products {

        "layout":"4:2:1:0",
        "wrapAround":false

      } /-->
      <div class="sep"><hr /></div>
    </div>

  </div>
  <div class="foot">
    <div class="sep"><hr /></div>
    <div class="box"></div>
  </div>
</div>

EOD;
# output
get_header('shop');
echo apply_filters('the_content', $o);
get_footer('shop');
?>
