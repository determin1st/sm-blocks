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

<div id="sm-page">
  <div class="head">
    <h3>sm-blocks</h3>
  </div>
  <div class="sep"><hr /></div>
  <div class="body">
    <div class="panel">
      <div class="title"><h3>...</h3></div>
      <div class="sep"><hr /></div>
      <div class="content">
        <!-- wp:sm-blocks/price-filter {$opf} /-->
        <!-- wp:sm-blocks/category-filter {$ocf} /-->
        <!-- :sm-blocks/category-filter {"baseCategory":"37"} /-->
      </div>
    </div>
    <div class="content">
      <div class="controls">
        <div class="column">
          <div class="sep h"><hr /></div>
          <!-- :sm-blocks/panel-slider {} /-->
          <div class="sep" style="width:0.5em;display:flex;align-items:center;padding:0 4px 0 4px;"><hr /></div>
          <div class="sep h"><hr /></div>
        </div>
        <div class="lines">
          <div>
          </div>
          <div>
            <!-- wp:sm-blocks/paginator {"gotoMode":3} /-->
            <!-- wp:sm-blocks/rows-selector {} /-->
            <!-- wp:sm-blocks/orderer {
              "switchMode":1
            } /-->
          </div>
        </div>
      </div>
      <div class="sep"><hr /></div>
      <!-- wp:sm-blocks/products {

        "layout":"4:2:1:0"

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
echo apply_filters('the_content', $o);
# done
get_footer('shop');
?>
