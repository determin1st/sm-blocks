<?php
/***
* Plugin Name: sm-blocks
* Description: A fully-asynchronous product catalogue for WooCommerce
* Plugin URI: github.com/determin1st/sm-blocks
* Author: determin1st
* Version: 0
* Requires at least: 5.4
* Requires PHP: 7.2
* License: UNLICENSE
* License URI: https://unlicense.org/
*/
class StorefrontModernBlocks {
  # base
  # data {{{
  private static
    $ref       = null;
  private
    $name      = 'sm-blocks',
    $db        = null,
    $prefix    = null,
    $lang      = 'en',
    $dir_data  = __DIR__.DIRECTORY_SEPARATOR.'data'.DIRECTORY_SEPARATOR,
    $dir_inc   = __DIR__.DIRECTORY_SEPARATOR.'inc'.DIRECTORY_SEPARATOR,
    $blocks    = [
      'grid' => [ # {{{
        'render_callback' => [null, 'renderGrid'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          ###
          'size'          => [
            'type'        => 'number',
            'default'     => 4,
          ],
          'columns'       => [
            'type'        => 'number',
            'default'     => 4,
          ],
          'columnsMin'    => [
            'type'        => 'number',
            'default'     => 1,
          ],
          'orderOptions' => [
            'type'        => 'string',
            'default'     => 'featured,new,price',
          ],
          'orderIndex'    => [
            'type'        => 'number',
            'default'     => 0,
          ],
          'maxX'          => [
            'type'        => 'number',
            'default'     => 304,
          ],
          'maxY'          => [
            'type'        => 'number',
            'default'     => 640,
          ],
          'itemSizeBalance' => [
            'type'        => 'string',
            'default'     => '35:40:25',
          ],
          'itemImage'     => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'itemIcon'      => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          'itemFeatures'  => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          'itemPrice'     => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'itemControls'  => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'fontSize'      => [
            'type'        => 'number',
            'default'     => 24,
          ],
        ],
      ],
      # }}}
      'category-filter' => [ # {{{
        'render_callback' => [null, 'renderCategoryFilter'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          ###
          'mode'          => [
            'type'        => 'string',
            'default'     => 'compact',
          ],
          'operator'      => [
            'type'        => 'string',
            'default'     => 'OR',
          ],
          'baseCategory'  => [
            'type'        => 'string',
            'default'     => '',
          ],
          'baseTitle'     => [
            'type'        => 'string',
            'default'     => '{"en":"Categories","ru":"Категории"}',
          ],
          'hasCount'      => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'hasEmpty'      => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          'subOpened'     => [
            'type'        => 'boolean',
            'default'     => false,
          ],
        ],
      ],
      # }}}
      'paginator' => [ # {{{
        'render_callback' => [null, 'renderPaginator'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          ###
          'modeFirstLast' => [
            'type'        => 'string',
            'default'     => 'inner',
          ],
          'modePrevNext'  => [
            'type'        => 'string',
            'default'     => 'standard',
          ],
          'range'         => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'rangeMode'     => [
            'type'        => 'number',
            'default'     => 2, # 0=none, 1=static, 2=flexy
          ],
          'rangePlus'     => [
            'type'        => 'number',
            'default'     => 2,
          ],
          'rangeMinus'  => [
            'type'        => 'number',
            'default'     => 1,
          ],
          'separator'     => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'bFirst'        => [
            'type'        => 'string',
            'default'     => '',
          ],
          'bLast'         => [
            'type'        => 'string',
            'default'     => '',
          ],
          'bPrev'         => [
            'type'        => 'string',
            'default'     => '',
          ],
          'bNext'         => [
            'type'        => 'string',
            'default'     => '',
          ],
          'bGap'          => [
            'type'        => 'string',
            'default'     => '',
          ],
          'bSep1'         => [
            'type'        => 'string',
            'default'     => '',
          ],
          'bSep2'         => [
            'type'        => 'string',
            'default'     => '',
          ],
        ],
      ],
      # }}}
      'orderer' => [ # {{{
        'render_callback' => [null, 'renderOrderer'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          ###
          'switchMode'    => [
            'type'        => 'number',
            'default'     => 1,
          ],
          'dropOnHover'   => [
            'type'        => 'boolean',
            'default'     => true,
          ],
        ],
      ],
      # }}}
      'price-filter' => [ # {{{
        'render_callback' => [null, 'renderPriceFilter'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          'dumbMode'      => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          ###
          'baseUI'        => [
            'type'        => 'number',
            'default'     => 0,
          ],
          'baseTitle'     => [
            'type'        => 'string',
            'default'     => '{"en":"Price","ru":"Цена"}',
          ],
          'sectionMode'   => [
            'type'        => 'number',
            'default'     => 0,
          ],
          'submitButton'  => [
            'type'        => 'number',
            'default'     => 0,
          ],
          'sliceGroups'   => [
            'type'        => 'number',
            'default'     => 0,
          ],
        ],
      ],
      # }}}
    ],
    $templates = [
      'grid' => [ # {{{
        'main' => '
        <div class="sm-blocks grid {{custom}}">
          <div class="{{class}}" style="{{style}}" {{data}}>
            {{items}}
          </div>
          {{placeholder}}
        </div>
        ',
        'item' => '
        <div class="item empty">
          <div class="box">
            {{itemImage}}
            <div class="body">
              {{itemIcon}}
              <div class="title ph">
                <div></div>{{emptyLine}}
              </div>
              {{itemFeatures}}
            </div>
            <div class="foot">
              {{itemPrice}}
              {{itemControls}}
            </div>
          </div>
        </div>
        ',
        # parts
        'itemImage' => '
        <div class="head ph">
          <div><img alt="product"></div>{{noImage}}
        </div>
        ',
        'itemIcon' => '
        <div class="icon">
          <div class="a ph">
            <div></div>{{noImage}}
          </div>
          <div class="b ph">
            <div></div>{{emptyLine}}
          </div>
        </div>
        ',
        'itemFeatures' => '
        <div class="features ph">
          <div></div>{{emptyBlock}}
        </div>
        ',
        'itemPrice' => '
        <div class="price ph">
          <div>
            <div class="v old">
              <span class="r0"></span>
              <span class="dot"></span>
              <span class="r1"></span>
            </div>
            <div class="v current">
              <div class="currency"></div>
              <div class="value c0">0</div>
              <div class="mantissa">
                <span class="dot"></span>
                <span class="c1">00</span>
              </div>
            </div>
          </div>
          {{emptyLine}}
        </div>
        ',
        'itemControls' => '
        <div class="controls ph">
          <div>
            <button class="cart">{{cartIcon}}</button>
            <a href="#" class="link">подробнее</a>
          </div>
          {{noControls}}
        </div>
        ',
        # icons
        'emptyBlock' => '
        <svg preserveAspectRatio="none" viewBox="0 0 24 24">
          <path d="M1 1v3h1V2h2V1H1zm19 0v1h2v2h1V1h-3zM1 20v3h3v-1H2v-2H1zm21 0v2h-2v1h3v-3h-1z"/>
        </svg>
        ',
        'emptyLine' => '
        <svg preserveAspectRatio="none" viewBox="0 0 1792 1792">
          <path d="M1920 576q53 0 90.5 37.5T2048 704v384q0 53-37.5 90.5T1920 1216v160q0 66-47 113t-113 47H-96q-66 0-113-47t-47-113V416q0-66 47-113t113-47h1856q66 0 113 47t47 113v160zm0 512V704h-128V416q0-14-9-23t-23-9H-96q-14 0-23 9t-9 23v960q0 14 9 23t23 9h1856q14 0 23-9t9-23v-288h128z"/>
        </svg>
        ',
        'noImage' => '
        <svg preserveAspectRatio="none" fill-rule="evenodd" clip-rule="evenodd" shape-rendering="geometricPrecision" viewBox="0 0 270.92 270.92">
          <path fill-rule="nonzero" d="M135.46 245.27c-28.39 0-54.21-10.93-73.72-28.67L216.6 61.74c17.74 19.51 28.67 45.33 28.67 73.72 0 60.55-49.26 109.81-109.81 109.81zm0-219.62c29.24 0 55.78 11.56 75.47 30.25L55.91 210.93c-18.7-19.7-30.25-46.23-30.25-75.47 0-60.55 49.26-109.81 109.8-109.81zm84.55 27.76c-.12-.16-.18-.35-.33-.5-.1-.09-.22-.12-.32-.2-21.4-21.7-51.09-35.19-83.9-35.19-65.03 0-117.94 52.91-117.94 117.94 0 32.81 13.5 62.52 35.2 83.91.08.09.11.22.2.31.14.14.33.2.49.32 21.24 20.63 50.17 33.4 82.05 33.4 65.03 0 117.94-52.91 117.94-117.94 0-31.88-12.77-60.8-33.39-82.05z"/>
        </svg>
        ',
        'noControls' => '
        <svg preserveAspectRatio="none" fill-rule="evenodd" clip-rule="evenodd" shape-rendering="geometricPrecision" viewBox="0 0 13547 13547">
          <path fill="none" d="M0 0h13547v13547H0z"/>
          <path d="M714 12832h12118V715H714v12117zm2566-5212h6985V5927H3280v1693z"/>
        </svg>
        ',
        'roundBox' => '
        <svg preserveAspectRatio="none" viewBox="0 0 48 48">
          <path fill="none" d="M0 0h48v48H0z"/>
          <path d="M24 12c4.9 0 9.42.39 14.58 1.27C39.52 16.84 40 20.45 40 24c0 3.55-.48 7.16-1.42 10.73C33.42 35.61 28.9 36 24 36s-9.42-.39-14.58-1.27C8.48 31.16 8 27.55 8 24c0-3.55.48-7.16 1.42-10.73C14.58 12.39 19.1 12 24 12m0-4c-5.46 0-10.45.48-15.91 1.44l-1.85.33-.5 1.79C4.58 15.7 4 19.85 4 24s.58 8.3 1.74 12.44l.5 1.79 1.85.33C13.55 39.52 18.54 40 24 40s10.45-.48 15.91-1.44l1.85-.33.5-1.79C43.42 32.3 44 28.15 44 24s-.58-8.3-1.74-12.44l-.5-1.79-1.85-.33C34.45 8.48 29.46 8 24 8z"/>
        </svg>
        ',
        'cartIcon' => '
        <svg preserveAspectRatio="none" viewBox="0 0 446.843 446.843">
          <path d="M444.09 93.103a14.343 14.343 0 00-11.584-5.888H109.92c-.625 0-1.249.038-1.85.119l-13.276-38.27a14.352 14.352 0 00-8.3-8.646L19.586 14.134c-7.374-2.887-15.695.735-18.591 8.1-2.891 7.369.73 15.695 8.1 18.591l60.768 23.872 74.381 214.399c-3.283 1.144-6.065 3.663-7.332 7.187l-21.506 59.739a11.928 11.928 0 001.468 10.916 11.95 11.95 0 009.773 5.078h11.044c-6.844 7.616-11.044 17.646-11.044 28.675 0 23.718 19.298 43.012 43.012 43.012s43.012-19.294 43.012-43.012c0-11.029-4.2-21.059-11.044-28.675h93.776c-6.847 7.616-11.048 17.646-11.048 28.675 0 23.718 19.294 43.012 43.013 43.012 23.718 0 43.012-19.294 43.012-43.012 0-11.029-4.2-21.059-11.043-28.675h13.433c6.599 0 11.947-5.349 11.947-11.948s-5.349-11.947-11.947-11.947H143.647l13.319-36.996c1.72.724 3.578 1.152 5.523 1.152h210.278a14.33 14.33 0 0013.65-9.959l59.739-186.387a14.33 14.33 0 00-2.066-12.828zM169.659 409.807c-10.543 0-19.116-8.573-19.116-19.116s8.573-19.117 19.116-19.117 19.116 8.574 19.116 19.117-8.573 19.116-19.116 19.116zm157.708 0c-10.543 0-19.117-8.573-19.117-19.116s8.574-19.117 19.117-19.117c10.542 0 19.116 8.574 19.116 19.117s-8.574 19.116-19.116 19.116zm75.153-261.658h-73.161V115.89h83.499l-10.338 32.259zm-21.067 65.712h-52.094v-37.038h63.967l-11.873 37.038zm-146.882 0v-37.038h66.113v37.038h-66.113zm66.113 28.677v31.064h-66.113v-31.064h66.113zm-161.569-65.715h66.784v37.038h-53.933l-12.851-37.038zm95.456-28.674V115.89h66.113v32.259h-66.113zm-28.673-32.259v32.259h-76.734l-11.191-32.259h87.925zm-43.982 126.648h43.982v31.064h-33.206l-10.776-31.064zm167.443 31.065v-31.064h42.909l-9.955 31.064h-32.954z"/>
        </svg>
        ',
      ],
      # }}}
      'category-filter' => [ # {{{
        'main' => '
        <div class="sm-blocks category-filter {{custom}}">
          <div data-op="{{operator}}">
            {{title}}{{topLine}}{{section}}{{bottomLine}}
          </div>
          {{placeholder}}
        </div>
        ',
        'title' => '
        <div class="title" data-id="0">
          <h3>{{name}}</h3>
          {{arrowBox}}
        </div>
        ',
        'item' => '
        <div class="item{{class}}" data-id="{{id}}" data-order="{{order}}" data-count="{{count}}">
          <div class="name">
            <div class="box">
              <input type="checkbox">
              <div class="check">{{checkmark}}{{indeterminate}}</div>
              <label>{{name}}</label>
            </div>
            {{countBox}}
            {{arrowBox}}
          </div>
          {{section}}
        </div>
        ',
        'section' => '
        <div class="section{{class}}">{{items}}</div>
        ',
        'countBox' => '
        <div class="count">({{count}})</div>
        ',
        'arrowBox' => '
        <div class="arrow">{{arrow}}</div>
        ',
        'topLine' => '
        <hr class="top">
        ',
        'bottomLine' => '
        <hr class="bottom">
        ',
        # icons
        'arrow' => '
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path stroke-linejoin="round" d="M8 12l2.5-4L13 4H3l2.5 4z"/>
        </svg>
        ',
        'checkmark' => '
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path stroke-linejoin="round" d="M5 6l3 3 5-6h1L8 13 3 7z"/>
        </svg>
        ',
        'indeterminate' => '
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path stroke-linejoin="round" d="M3 6.5h10v3H3z"/>
        </svg>
        ',
      ],
      # }}}
      'paginator' => [ # {{{
        'main' => '
        <div class="sm-blocks paginator {{custom}}">
          <div class="{{class}}">{{content}}</div>
          {{placeholder}}
        </div>
        ',
        'first' => '
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M58.644 27.26v8.294c0 .571-.305 1.1-.8 1.385L37.632 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L16.869 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
          <path d="M57.844 63.048l-2.376-1.372c-.013.043-.023.09-.032.136l.409.236c.495.286.8.814.8 1.385v8.294c0 1.008-.894 1.693-1.803 1.575l1.404.81a1.6 1.6 0 002.399-1.385v-8.294a1.603 1.603 0 00-.801-1.385zM37.632 48.608l20.212-11.669a1.6 1.6 0 00.8-1.385V27.26c0-1.115-1.092-1.84-2.091-1.512.054.16.091.328.091.512v8.294c0 .571-.305 1.1-.8 1.385L35.632 47.608c-.078.052-.745.516-.8 1.385-.057.911.609 1.467.673 1.518l1.916 1.328a.747.747 0 01.019-.51.575.575 0 01.037-.07c-.895-.672-.852-2.069.155-2.651z"/>
          <path fill="none" stroke-miterlimit="10" d="M58.644 27.26v8.294c0 .571-.305 1.1-.8 1.385L37.632 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L16.869 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
          <path d="M86.058 27.26v8.294c0 .571-.305 1.1-.8 1.385L65.047 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L44.283 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
          <path d="M85.258 63.048l-2.376-1.372c-.013.043-.023.09-.032.136l.409.236c.495.286.8.814.8 1.385v8.294c0 1.008-.894 1.693-1.803 1.575l1.404.81a1.6 1.6 0 002.399-1.385v-8.294a1.603 1.603 0 00-.801-1.385zM65.047 48.608l20.212-11.669a1.6 1.6 0 00.8-1.385V27.26c0-1.115-1.092-1.84-2.091-1.512.054.16.091.328.091.512v8.294c0 .571-.305 1.1-.8 1.385L63.047 47.608c-.078.052-.745.516-.8 1.385-.057.911.609 1.467.673 1.518l1.916 1.328a.747.747 0 01.019-.51.575.575 0 01.037-.07c-.896-.672-.853-2.069.155-2.651z"/>
          <path fill="none" stroke-miterlimit="10" d="M86.058 27.26v8.294c0 .571-.305 1.1-.8 1.385L65.047 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L44.283 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
        </svg>
        ',
        'last' => '
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M41.762 27.26v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L42.562 63.048a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L44.161 25.875a1.6 1.6 0 00-2.399 1.385z"/>
          <path d="M83.537 48.608L44.161 25.875a1.56 1.56 0 00-.597-.19l37.972 21.923a1.6 1.6 0 010 2.771L42.161 73.112c-.1.058-.205.092-.308.126.308.914 1.401 1.398 2.308.874l39.375-22.733a1.6 1.6 0 00.001-2.771z"/>
          <path fill="none" stroke-miterlimit="10" d="M41.762 27.26v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L42.562 63.048a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L44.161 25.875a1.6 1.6 0 00-2.399 1.385z"/>
          <path d="M14.664 27.273v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L15.464 63.061a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L17.063 25.888a1.6 1.6 0 00-2.399 1.385z"/>
          <path d="M56.438 48.621L17.063 25.888a1.56 1.56 0 00-.597-.19l37.972 21.923a1.6 1.6 0 010 2.771L15.063 73.125c-.1.058-.205.092-.308.126.308.914 1.401 1.398 2.308.874l39.375-22.733a1.6 1.6 0 000-2.771z"/>
          <path fill="none" stroke-miterlimit="10" d="M14.664 27.273v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L15.464 63.061a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L17.063 25.888a1.6 1.6 0 00-2.399 1.385z"/>
        </svg>
        ',
        'prev' => '
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M70.787 27.267v8.294c0 .571-.305 1.1-.8 1.385L49.776 48.615a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L29.013 51.385a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.399 1.386z"/>
          <path d="M69.987 63.055l-2.376-1.372c-.013.043-.023.09-.032.136l.409.236c.495.286.8.814.8 1.385v8.294c0 1.008-.894 1.693-1.803 1.575l1.404.81a1.6 1.6 0 002.399-1.385V64.44a1.6 1.6 0 00-.801-1.385zM49.776 48.615l20.212-11.669a1.6 1.6 0 00.8-1.385v-8.294c0-1.115-1.092-1.84-2.091-1.512.054.16.091.328.091.512v8.294c0 .571-.305 1.1-.8 1.385L47.776 47.615c-.078.052-.745.516-.8 1.385-.057.911.609 1.467.673 1.518l1.916 1.328a.747.747 0 01.019-.51.575.575 0 01.037-.07c-.896-.673-.853-2.07.155-2.651z"/>
          <path fill="none" stroke-miterlimit="10" d="M70.787 27.267v8.294c0 .571-.305 1.1-.8 1.385L49.776 48.615a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L29.013 51.385a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.399 1.386z"/>
        </svg>
        ',
        'next' => '
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M28.213 27.267v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L29.013 63.055a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L30.612 25.881a1.6 1.6 0 00-2.399 1.386z"/>
          <path d="M69.987 48.615L30.612 25.881a1.56 1.56 0 00-.597-.19l37.972 21.923a1.6 1.6 0 010 2.771L28.612 73.119c-.1.058-.205.092-.308.126.308.914 1.401 1.398 2.308.874l39.375-22.733a1.6 1.6 0 000-2.771z"/>
          <path fill="none" stroke-miterlimit="10" d="M28.213 27.267v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L29.013 63.055a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L30.612 25.881a1.6 1.6 0 00-2.399 1.386z"/>
        </svg>
        ',
        'gap' => '
        <svg preserveAspectRatio="none" viewBox="0 0 48 48">
          <path d="M1 41h14v6H1zM17 41h14v6H17zM33 41h14v6H33z"/>
        </svg>
        ',
        'gapExp' => '
        <svg preserveAspectRatio="none" viewBox="0 0 48 48">
          <rect y="4" width="48" height="40"/>
        </svg>
        ',
        'sep1' => '
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path d="M3 .997h6v14H3zM10 1.997h3v12h-3z"/>
        </svg>
        ',
        'sep2' => '
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path d="M7 .997h6v14H7zM3 1.997h3v12H3z"/>
        </svg>
        ',
      ],
      # }}}
      'orderer' => [ # {{{
        'main' => '
        <div class="sm-blocks orderer {{custom}}">
          <div>
            {{variantLeft}}
            <select class="{{class}}"></select>
            {{variantRight}}
          </div>
          {{placeholder}}
        </div>
        ',
        'variantLeft' => '
        <div class="variant left">
          <button>{{arrow}}</button>
        </div>
        ',
        'variantRight' => '
        <div class="variant right">
          <button>{{arrow}}</button>
        </div>
        ',
        'arrow' => '
        <svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
          <path stroke-linejoin="round" d="M11 25l13 13 13-13h-2l-8 5-2-19-1-1-1 1-2 19-8-5z"/>
        </svg>
        ',
        'asc_desc' => '
        <svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
          <path stroke-linejoin="round" d="M11 25l13 13 13-13h-2l-8 5-1-6 1-6 8 5h2L24 10 11 23h2l8-5 1 6-1 6-8-5z"/>
        </svg>
        ',
      ],
      # }}}
      'price-filter' => [ # {{{
        'main' => '
        <div class="sm-blocks price-filter {{custom}}">
          {{content}}{{placeholder}}
        </div>
        ',
        'textInputs' => '
        <div class="left"><input type="text" inputmode="numeric" pattern="[0-9]*"></div>
        {{delimiter}}
        <div class="right"><input type="text" inputmode="numeric" pattern="[0-9]*"></div>
        {{submitButton}}
        ',
        'rangeSlider' => '
        ',
        'submitButton' => '
        <div class="submit" data-mode="1">
          <button>{{submitIcon}}</button>
        </div>
        ',
        'delimiter' => '
        <svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
          <polygon points="0,48 4,48 12,43 18,41 22,40 26,40 30,41 36,43 44,48 48,48 48,0 44,0 36,5 30,7 26,8 22,8 18,7 12,5 4,0 0,0 "/>
          <polygon class="left"       points="13,28 16,31 19,32 23,32 23,31 19,30 17,28 16,24 17,20 19,18 23,17 23,16 19,16 16,17 13,20 12,22 12,26 "/>
          <polygon class="inputState" points="18,28 20,30 24,31 28,30 30,28 31,24 30,20 28,18 24,17 20,18 18,20 17,24 "/>
          <polygon class="right"      points="35,28 32,31 29,32 25,32 25,31 29,30 31,28 32,24 31,20 29,18 25,17 25,16 29,16 32,17 35,20 36,22 36,26 "/>
        </svg>
        ',
      ],
      # }}}
      'section' => [ # {{{
        'main' => '
        <div class="main-section{{class}}"{{data}}>
          {{title}}
          {{topLine}}
          {{items}}
          {{bottomLine}}
        </div>
        ',
        'title' => '
        <div class="title" data-id="0">
          <h3>{{name}}</h3>
          {{arrowBox}}
        </div>
        ',
        'item' => '
        <div class="item{{class}}" data-id="{{id}}" data-order="{{order}}" data-extra="{{extraData}}">
          <div class="name">
            <div class="box">{{itemTitle}}</div>
            {{extraBox}}
            {{arrowBox}}
          </div>
          {{section}}
        </div>
        ',
        'section' => '
        <div class="section{{class}}">{{items}}</div>
        ',
        'extraBox' => '
        <div class="extra">{{extra}}</div>
        ',
        'arrowBox' => '
        <div class="arrow">{{arrow}}</div>
        ',
        'topLine' => '
        <hr class="top">
        ',
        'bottomLine' => '
        <hr class="bottom">
        ',
        'arrow' => '
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path stroke-linejoin="round" d="M8 12l2.5-4L13 4H3l2.5 4z"/>
        </svg>
        ',
      ],
      # }}}
      'svg' => [ # {{{
        'placeholder' => '
        <svg preserveAspectRatio="none" viewBox="0 0 48 48">
          <path d="M1 47h46V1H1v46z"/>
        </svg>
        ',
      ],
      # }}}
    ],
    $cfg       = [
      'enableDemoShop' => true,
      'purgeTimeout'   => 86400,
      'cache'          => [],
    ];
  # }}}
  # constructor {{{
  private function __construct()
  {
    global $wpdb;
    # prepare
    $this->db     = $wpdb->dbh;
    $this->prefix = $wpdb->prefix;
    $this->lang   = substr(get_locale(), 0, 2);
    # load configuration
    $a = $this->dir_data.'config.txt';
    if (file_exists($a)) {
      $this->cfg = unserialize(file_get_contents($a));
    }
    else {
      file_put_contents($a, serialize($this->cfg));
    }
    # initialize block data
    foreach ($this->blocks as &$a) {
      $a['render_callback'][0] = $this;
    }
    unset($a);
    # register dependency scripts
    # some scripts are separate projects that may be included
    # locally (from the same-origin) or remotely (from cdn)
    $a = plugins_url().'/'.$this->name.'/';
    wp_register_script(
      'http-fetch',
      file_exists($this->dir_inc.'httpFetch')
        ? $a.'inc/httpFetch/httpFetch.js'
        : 'https://cdn.jsdelivr.net/npm/http-fetch-json@2/httpFetch.js',
      [], false, true
    );
    # register core styles and scripts
    wp_register_style(
      $this->name.'-css',
      $a.'css/'.$this->name.'.css'
    );
    wp_register_style(
      $this->name.'-design-css',
      $a.'css/'.$this->name.'-design.css',
      [$this->name.'-css']
    );
    wp_register_style(
      $this->name.'-demo-css',
      $a.'css/'.$this->name.'-demo.css'
    );
    wp_register_script(
      $this->name.'-js',
      $a.'js/'.$this->name.'.js',
      ['http-fetch'],
      false, true
    );
    wp_register_script(
      $this->name.'-design-js',
      $a.'js/'.$this->name.'-design.js',
      [
        'wp-blocks', 'wp-element',
        'wp-editor', 'wp-components'
      ],
      false, true
    );
    # set registration hooks
    $me = $this;
    add_action('init', function() use ($me) {
      foreach ($me->blocks as $a => $b) {
        register_block_type($me->name.'/'.$a, $b);
      }
    });
    add_action('rest_api_init', function() use ($me) {
      register_rest_route($me->name, 'kiss', [
        'methods'  => 'POST',
        'callback' => [$me, 'apiKiss'],
      ]);
    });
    add_action('enqueue_block_assets', function() use ($me) {
      if (is_admin())
      {
        # design mode
        wp_enqueue_style($me->name.'-design-css');
        wp_enqueue_script($me->name.'-design-js');
      }
      else
      {
        # usage mode
        wp_enqueue_style($me->name.'-css');
        wp_enqueue_script($me->name.'-js');
        # check demo-shop
        if ($me->cfg['enableDemoShop'] && is_shop()) {
          wp_enqueue_style($me->name.'-demo-css');
        }
        # for removing gutenberg's default/core blocks:
        #wp_dequeue_style('wp-block-library');
        #wp_deregister_style('wp-block-library');
      }
    });
    # set demo-shop template
    if ($this->cfg['enableDemoShop'])
    {
      add_filter('template_include', function($t) {
        return is_shop()
          ? __DIR__.DIRECTORY_SEPARATOR.'sm-blocks-demo.php'
          : $t;
        ###
      }, 11, 1);
    }
  }
  public static function init()
  {
    # construct once (singleton)
    if (self::$ref === null) {
      self::$ref = new StorefrontModernBlocks();
    }
    return self::$ref;
  }
  # }}}
  # ssr rendering
  # grid {{{
  public function renderGrid($attr, $content)
  {
    # prepare
    $T = $this->templates['grid'];
    $D = $this->blocks['grid']['attributes'];
    $class = $style = $data = $items = '';
    # create elements
    # grid items {{{
    $size    = $attr['size'];
    $columns = (($a = $attr['columns']) > $size)
      ? $size
      : $a;
    $rows    = (($a = $size / $columns) % 1)
      ? ($rows | 0) + 1
      : $a;
    # clone
    $a = $this->parseTemplate($T['item'], $T, $attr);
    $b = 1 + $size;
    while (--$b) {
      $items .= $a;
    }
    # }}}
    # class name and style {{{
    $class = $columns === 1
      ? 'list'
      : '';
    # using default to ssr-preset comparison here,
    # expands logic into 2 equal mod directions:
    # CSS class preset and/or SSR inline preset
    $style = "--columns:{$columns};--rows:{$rows};";
    if ($attr['maxX'] != $D['maxX']['default']) {
      $style .= "--item-max-x:{$attr['maxX']}px;";
    }
    if ($attr['maxY'] != $D['maxY']['default']) {
      $style .= "--item-max-y:{$attr['maxY']}px;";
    }
    if (($a = trim(substr($attr['itemSizeBalance'], 0, 20))) &&
        $a !== $D['itemSizeBalance']['default'] &&
        ($a = explode(':', $a)) && count($a) === 3 &&
        ($a[0] = intval($a[0])) > 0 && $a[0] < 100 &&
        ($a[1] = intval($a[1])) > 0 && $a[1] < 100 &&
        ($a[2] = intval($a[2])) > 0 && $a[2] < 100 &&
        ($a[0] + $a[1] + $a[2]) <= 100)
    {
      $style .= "--item-sz-1:{$a[0]};--item-sz-2:{$a[1]};--item-sz-3:{$a[2]}";
    }
    # }}}
    # data attributes {{{
    # these are client-controller side options which serve
    # only the script's logic, with no direct effect on styles
    # 1: minimal count of columns in the grid
    $a = (!($b = intval($attr['columnsMin'])) || $b > $columns)
      ? $columns
      : $b;
    $data .= ' data-cols="'.$a.'"';
    # 2: the order of the records
    $a = (!($b = $attr['orderOptions']) || empty($b))
      ? $D['orderOptions']['default']
      : $b;
    $data .= ' data-order="'.$a.'"';
    $a = (!($b = $attr['orderIndex']) || empty($b))
      ? $D['orderIndex']['default']
      : $b;
    $data .= ' data-index="'.$a.'"';
    # complete
    $data = trim($data);
    # }}}
    # compose
    return $this->parseTemplate($T['main'], $T, [
      'custom' => $attr['customClass'],
      'class'  => $class,
      'style'  => $style,
      'data'   => $data,
      'items'  => $items,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # category-filter {{{
  public function renderCategoryFilter($attr, $content)
  {
    # get data
    $a = $attr['baseCategory'];
    $b = $attr['hasEmpty'];
    if (!($root = $this->getCategoryTree($a, $b))) {
      return '';
    }
    # set root title
    if (empty($a)) {
      $root['name'] = $this->parseLocalName($attr['baseTitle']);
    }
    # get templates
    $T = $this->templates['category-filter'];
    # create recursive helper
    $f = function($node) use (&$f, $T, $attr)
    {
      # {{{
      $html = '';
      foreach ($node['list'] as $a)
      {
        # create item template parameters
        if ($a['list'])
        {
          $b = [
            'class'    => [
              ' sub', ($attr['subOpened'] ? ' opened' : '')
            ],
            'id'       => $a['id'],
            'order'    => $a['order'],
            'count'    => $a['count'],
            'name'     => $a['name'],
            'countBox' => false,
            'items'    => $f($a),
          ];
        }
        else
        {
          $b = [
            'class'    => '',
            'id'       => $a['id'],
            'order'    => $a['order'],
            'count'    => $a['count'],
            'name'     => $a['name'],
            'arrowBox' => false,
            'section'  => false,
          ];
        }
        # aggregate markup
        $html .= $this->parseTemplate($T['item'], $T, $b).$c;
      }
      # complete
      return $html;
      # }}}
    };
    # build categories tree
    if (!($items = $f($root))) {
      return '';
    }
    # determine main section parameters
    switch ($b = $attr['mode']) {
    case 'none':
      $a = [
        'title'      => false,
        'topLine'    => false,
        'bottomLine' => false,
        'class'      => ' opened',
      ];
      break;
    case 'compact':
      $a = [
        'name'       => $root['name'],
        'arrowBox'   => false,
        'class'      => ' opened',
        'bottomLine' => false,
      ];
      break;
    default:
      $a = [
        'name'       => $root['name'],
        'class'      => ($b === 'collapsed' ? '' : ' opened'),
      ];
      break;
    }
    # compose
    return $this->parseTemplate($T['main'], $T, array_merge($a, [
      'custom'      => $attr['customClass'],
      'operator'    => $attr['operator'],
      'items'       => $items,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]));
  }
  # }}}
  # paginator {{{
  public function renderPaginator($attr, $content)
  {
    # prepare
    $T = $this->templates['paginator'];
    # create elements
    # first/last {{{
    if (($a = $attr['modeFirstLast']) !== 'none')
    {
      # create inner buttons
      if ($a === 'inner' || $a === 'both')
      {
        $iFirst = '<div class="page first"><button>1</button></div>';
        $iLast  = '<div class="page last"><button>n</button></div>';
      }
      else {
        $iFirst = $iLast = '';
      }
      # create outer buttons
      if ($a === 'outer' || $a === 'both')
      {
        $oFirst = empty($attr['bFirst'])
          ? $T['first']
          : $attr['bFirst'];
        $oLast  = empty($attr['bLast'])
          ? $T['last']
          : $attr['bLast'];
        $oFirst = '<div class="goto a first"><button>'.$oFirst.'</button></div>';
        $oLast  = '<div class="goto a last"><button>'.$oLast.'</button></div>';
      }
      else {
        $oFirst = $oLast = '';
      }
    }
    else {
      $iFirst = $iLast = $oFirst = $oLast = '';
    }
    # }}}
    # previous/next {{{
    if (($a = $attr['modePrevNext']) !== 'none')
    {
      $prev = $a === 'standard' || empty($attr['bPrev'])
        ? $T['prev']
        : $attr['bPrev'];
      $next = $a === 'standard' || empty($attr['bNext'])
        ? $T['next']
        : $attr['bNext'];
      ###
      $prev = '<div class="goto b prev"><button>'.$prev.'</button></div>';
      $next = '<div class="goto b next"><button>'.$next.'</button></div>';
    }
    else {
      $prev = $next = '';
    }
    # }}}
    # gap/separator {{{
    $gap = empty($attr['bGap'])
      ? ($attr['rangeMode'] === 2
        ? $T['gapExp']
        : $T['gap'])
      : $attr['bGap'];
    $gapFirst = '<div class="gap first">'.$gap.'</div>';
    $gapLast  = '<div class="gap last">'.$gap.'</div>';
    ###
    $sepFirst = $sepMid = $sepLast = '';
    if ($attr['separator'])
    {
      $sepFirst = empty($attr['bSep1'])
        ? $T['sep1']
        : $attr['bSep1'];
      $sepLast  = empty($attr['bSep2'])
        ? $T['sep2']
        : $attr['bSep2'];
      $sepFirst = '<div class="sep first">'.$sepFirst.'</div>';
      $sepMid   = '<div class="sep">'.$sepFirst.'</div>';
      $sepLast  = '<div class="sep last">'.$sepLast.'</div>';
    }
    # }}}
    # range {{{
    if ($attr['rangeMode'])
    {
      # prepare
      $rangeLeft = $rangeRight = '';
      $b = $attr['rangeMinus'];
      $c = $attr['rangePlus'];
      # compose parts
      $a = $b + 1;
      while (--$a > 0)
      {
        $rangeLeft .= '
        <div class="page x">
          <button>x-'.$a.'</button>
        </div>
        ';
      }
      while (++$a <= $c)
      {
        $rangeRight .= '
        <div class="page x">
          <button>x-'.$a.'</button>
        </div>
        ';
      }
      # add gaps
      if (!empty($rangeLeft)  ||
          !empty($rangeRight) ||
          !empty($iFirst))
      {
        $rangeLeft  = $gapFirst.$rangeLeft;
        $rangeRight = $rangeRight.$gapLast;
      }
      # determine capacity
      $a = empty($iFirst) ? 0 : 2;
      $a = $a + $b + 1 + $c;
      # compose
      $content = <<<EOD
      {$sepFirst}
      <div class="range" style="--count:{$a}">
        {$iFirst}
        {$rangeLeft}
        <div class="page x current"><button>x</button></div>
        {$rangeRight}
        {$iLast}
      </div>
      {$sepLast}
EOD;
    }
    else
    {
      # no range
      $content = $sepMid;
    }
    # }}}
    # class name {{{
    $class = $attr['rangeMode'];
    $class = $class === 2
      ? 'flexy'
      : ($class === 1
        ? 'static'
        : 'norange');
    if (empty($sepFirst)) {
      $class .= ' nosep';
    }
    # }}}
    # compose
    return $this->parseTemplate($T['main'], $T, [
      'custom'  => $attr['customClass'],
      'class'   => $class,
      'content' => $oFirst.$prev.$content.$next.$oLast,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # orderer {{{
  public function renderOrderer($attr, $content)
  {
    # prepare
    $T = $this->templates['orderer'];
    # determine class
    $variantL = true;
    $variantR = true;
    switch ($attr['switchMode']) {
    case 1:
      $class    = 'left';
      $variantR = false;
      break;
    case 2:
      $class    = 'right';
      $variantL = false;
      break;
    default:
      $class = 'left right';
      break;
    }
    # complete
    return $this->parseTemplate($T['main'], $T, [
      'custom' => $attr['customClass'],
      'class'  => $class,
      'variantLeft'  => $variantL,
      'variantRight' => $variantR,
      'placeholder'  => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # price-filter {{{
  public function renderPriceFilter($attr, $content)
  {
    # prepare
    $T = $this->templates['price-filter'];
    # create filter variant
    switch ($attr['baseUI']) {
    default:
      $content = $this->parseTemplate($T['textInputs'], $T, [
        'submitButton' => ($attr['submitButton'] !== 0),
      ]);
      $class = 'text';
      break;
    }
    # create section
    $content = $this->renderSection([
      'class' => $class,
      'data'  => '',
      'mode'  => $attr['sectionMode'],
      'name'  => $this->parseLocalName($attr['baseTitle']),
      'items' => $content,
    ]);
    # compose
    return $this->parseTemplate($T['main'], $T, [
      'custom'  => $attr['customClass'],
      'content' => $content,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # section {{{
  private function renderSection($attr)
  {
    # preapre
    $T = $this->templates['section'];
    # compose sections tree
    $mode    = $attr['mode'];
    $content = $attr['items'];
    if (is_array($content))
    {
      $content = $this->renderSectionItems($items, $T, [
      ]);
      if (!$content || empty($content)) {
        return '';
      }
    }
    # determine main section parameters
    switch ($mode) {
    case 1:
      # compact (title|content)
      $a = [
        'class'      => $attr['class'].' opened',
        'name'       => $attr['name'],
        'arrowBox'   => false,
        'bottomLine' => false,
      ];
      break;
    case 2:
      # full opened (title^|content|)
      $a = [
        'class' => $attr['class'].' opened',
        'name'  => $attr['name'],
      ];
      break;
    case 3:
      # full closed (title^|content|)
      $a = [
        'class' => $attr['class'],
        'name'  => $attr['name'],
      ];
      break;
    default:
      # content only (empty section)
      $a = [
        'class'      => $attr['class'].' opened',
        'title'      => false,
        'topLine'    => false,
        'bottomLine' => false,
      ];
      break;
    }
    # compose
    $a['class'] = ' '.trim($a['class']);
    $a['data']  = empty($attr['data']) ? '' : ' '.$attr['data'];
    $a['items'] = $content;
    return $this->parseTemplate($T['main'], $T, $a);
  }
  private function renderSectionItems($node, $T, $attr)
  {
    $html = '';
    foreach ($node['list'] as $a)
    {
      # create item template parameters
      if ($a['list'])
      {
        $b = [
          'class'    => [
            ' sub', ($attr['subOpened'] ? ' opened' : '')
          ],
          'id'       => $a['id'],
          'order'    => $a['order'],
          'extra'    => $a['extra'],
          'name'     => $a['name'],
          'countBox' => false,
          'items'    => $this->renderSectionItem($a, $T, $attr),
        ];
      }
      else
      {
        $b = [
          'class'    => '',
          'id'       => $a['id'],
          'order'    => $a['order'],
          'extra'    => $a['extra'],
          'name'     => $a['name'],
          'arrowBox' => false,
          'section'  => false,
        ];
      }
      # aggregate markup
      $html .= $this->parseTemplate($T['item'], $T, $b).$c;
    }
    # complete
    return $html;
  }
  # }}}
  # rest api
  # entry point {{{
  public function apiKiss($request)
  {
    # get parameters
    if (!($request = $request->get_json_params()) ||
        !is_array($request))
    {
      $this->apiFail(400, 'incorrect request');
    }
    # check
    if (!array_key_exists('func', $request)) {
      $this->apiFail(400, 'missing request function');
    }
    # operate
    switch ($request['func']) {
    case 'grid':
      $this->apiGrid($request);
      break;
    case 'cart':
      $this->apiCart($request);
      break;
    case 'config':
      # {{{
      # determine language
      $a = array_key_exists('lang', $request)
        ? $request['lang']
        : $this->lang;
      # load data
      $b = __DIR__.DIRECTORY_SEPARATOR.$this->name.'-config.php';
      $b = (include $b);
      $b = array_key_exists($a, $b)
        ? $b[$a]
        : $b['en'];
      # output
      header('content-type: application/json');
      echo json_encode($b);
      # }}}
      break;
    default:
      $this->apiFail(400, 'unknown request function');
      break;
    }
    # terminate
    exit;
  }
  # }}}
  # grid {{{
  private function apiGrid($request)
  {
    # checkout request parameters
    # {{{
    # check must have
    $a = [
      'limit',
      'offset',
      'category',
      'order',
    ];
    foreach ($a as $b)
    {
      if (!array_key_exists($b, $request)) {
        $this->apiFail(400, 'missing "'.$b.'" in the request');
      }
    }
    # check limit and offset
    $limit  = intval($request['limit']);
    $offset = intval($request['offset']);
    if ($limit < 0 || $limit > 200 || $offset < 0) {
      $this->apiFail(400, 'incorrect limit/offset');
    }
    # category filter
    if (!($cats = $request['category']) ||
        !is_array($cats) || count($cats) === 0)
    {
      $cats = null;
    }
    else
    {
      $c = 'incorrect category filter data';
      foreach ($cats as $a)
      {
        if (!is_array($a)) {
          $this->apiFail(400, $c);
        }
        foreach ($a as $b)
        {
          if (!is_int($b) || $b < 0) {
            $this->apiFail(400, $c);
          }
        }
      }
    }
    # check order parameter
    $a = $request['order'];
    if (!is_array($a) || !is_string($a[0]) || !is_int($a[1])) {
      $this->apiFail(400, 'incorrect order parameter');
    }
    # }}}
    # get product identifiers
    $ids = [
      'order'    => $request['order'],
      'category' => $cats,
      #'status'  => ['publish'],
      #'type'    => ['external','grouped','simple','variable']
    ];
    if (!($ids = $this->getProductIds($ids))) {
      $this->apiFail(500, 'failed to fetch products');
    }
    # get total count and check overflow
    $total = count($ids);
    if ($offset >= $total) {
      $this->apiFail(400, 'incorrect offset, too large');
    }
    # extract and use limited set
    $ids = array_slice($ids, $offset, $limit);
    # activate streaming
    if (session_status() === PHP_SESSION_ACTIVE) {
      session_write_close();
    }
    while (ob_get_level() !== 0) {
      ob_end_clean();
    }
    header('content-type: application/octet-stream');
    # send total count
    $this->sendInt($total);
    # get currency settings
    $currency = $this->getCurrency();
    # stream products
    foreach ($ids as $id)
    {
      # TODO: cache?
      # get product
      if (!($a = $this->getProduct($id))) {
        break;
      }
      # create transferable item
      $item = [
        'currency' => $currency,
        'id'       => intval($id),
        'name'     => $a['name'],
        'type'     => $a['product_type'],
        'link'     => get_permalink($id),
        'image'    => null,
        'price'    => null,
        'stock'    => [
          'status'    => $a['_stock_status'],
          'backorder' => $a['_backorders'],
          'count'     => (($a['_stock'] !== null)
            ? intval($a['_stock'])
            : null
          ),
        ],
      ];
      # set image
      if (array_key_exists('_thumbnail_id', $a) &&
          ($b = $a['_thumbnail_id']) && !empty($b) &&
          ($c = wp_get_attachment_url($b)))
      {
        $item['image'] = [
          'src'    => $c,
          'srcset' => wp_get_attachment_image_srcset($b, 'full'),
        ];
      }
      # set price (TODO: other types)
      switch ($item['type']) {
      case 'simple':
        $item['price'] = [
          $a['_regular_price'], $a['_price']
        ];
        break;
      }
      # transfer
      $this->sendJSON($item);
      #usleep(500 * 1000);
    }
  }
  # }}}
  # cart {{{
  private function apiCart($request)
  {
    # check
    if (!array_key_exists('op', $request)) {
      $this->apiFail(400, 'missing request operation');
    }
    # handle
    switch ($request['op']) {
    case 'get':
      # get cart items
      echo json_encode($this->getCart());
      break;
    case 'set':
      # extract and validate request parameters
      if (!array_key_exists('id', $request) ||
          ($id = intval($request['id'])) < 0)
      {
        $this->apiFail(400, 'incorrect identifier');
      }
      # set cart item
      if (!$this->setCart($id)) {
        $this->apiFail(500, 'failed to set cart');
      }
      echo json_encode(true);
      break;
    default:
      $this->apiFail(400, 'unknown request operation');
      break;
    }
  }
  # }}}
  # helpers
  # parsers {{{
  private function parseTemplate($template, $data, $attr = [])
  {
    $depth = 0;
    while (true)
    {
      # get template tokens
      $list = [];
      if (!preg_match_all('/{{([^}]+)}}/', $template, $list) ||
          count($list) < 2 || count($list[1]) === 0)
      {
        break;# nothing to substitute
      }
      $list = $list[1];
      # iterate
      $c = 0;
      foreach ($list as $a)
      {
        # prepare
        $b = null;
        # check attribute specified
        if (array_key_exists($a, $attr))
        {
          if (is_array($attr[$a])) {
            $b = $attr[$a][$depth];
          }
          else if (!is_bool($attr[$a])) {
            $b = $attr[$a];
          }
          else if (!$attr[$a]) {
            $b = '';
          }
        }
        # check data
        if ($b === null && array_key_exists($a, $data)) {
          $b = $data[$a];
        }
        # substitute
        if ($b !== null)
        {
          $template = str_replace('{{'.$a.'}}', $b, $template);
          ++$c;
        }
      }
      # check count
      if ($c === 0)
      {
        # no more substitutions possible,
        # wipe all markers and complete
        foreach ($list as $a) {
          $template = str_replace('{{'.$a.'}}', '', $template);
        }
        break;
      }
      # continue
      ++$depth;
    }
    # remove extra gaps and complete
    return preg_replace('/>\s+</', '><', $template);
  }
  private function parseLocalName($json)
  {
    # parse JSON string into array
    if (($json = json_decode($json, true)) === null) {
      return '';
    }
    # check hardcoded
    if (!is_array($json)) {
      return is_string($json) ? $json : '';
    }
    # check localized name exists
    if (array_key_exists($this->lang, $json)) {
      $json = $json[$this->lang];
    }
    else if (array_key_exists('en', $json)) {
      $json = $json['en'];
    }
    else {
      return '';
    }
    # complete
    return is_string($json) ? $json : '';
  }
  # }}}
  # apis {{{
  private function apiFail($code, $msg)
  {
    http_response_code($code);
    header('content-type: text/plain');
    echo $msg;
    flush();
    exit;
  }
  private function sendInt($i)
  {
    # convert and send as big-endian value
    echo pack('N', $i);
    flush();
    # done
    return true;
  }
  private function sendJSON($o)
  {
    # create json string
    if (($o = json_encode($o)) === false) {
      return false;
    }
    # send size and content
    echo pack('N', strlen($o));
    echo $o;
    flush();
    # done
    return true;
  }
  # }}}
  # database processing {{{
  public function getProductIds($o) # {{{
  {
    # prepare
    $joins = $filts = $order = '';
    # compose filters {{{
    if ($a = $o['category'])
    {
      $joins .= <<<EOD

        JOIN {$this->prefix}term_taxonomy AS tCat
          ON tCat.taxonomy = 'product_cat'
        JOIN {$this->prefix}term_relationships AS tCatRel
          ON tCatRel.term_taxonomy_id = tCat.term_taxonomy_id AND
             tCatRel.object_id = p.ID

EOD;
      foreach ($a as $b)
      {
        $b = implode(',', $b);
        $filts .= "AND tCatRel.term_taxonomy_id IN ({$b}) ";
      }
    }
    # }}}
    # compose order {{{
    switch ($o['order'][0]) {
    case 'featured':
      $joins .= <<<EOD

        LEFT JOIN {$this->prefix}terms as tFeatured
          ON tFeatured.name = 'featured'
        LEFT JOIN {$this->prefix}term_relationships as tFeatRel
          ON tFeatRel.term_taxonomy_id = tFeatured.term_id AND
             tFeatRel.object_id = p.ID

EOD;
      $order = 'tFeatRel.term_taxonomy_id DESC, p.menu_order, p.post_title';
      break;
    case 'new':
      $order = 'p.post_date DESC, p.post_title';
      break;
    case 'price':
      $joins .= <<<EOD

        LEFT JOIN {$this->prefix}postmeta as mPrice
          ON mPrice.post_id  = p.ID AND
             mPrice.meta_key = '_price'

EOD;
      $order = 'CAST(mPrice.meta_value AS SIGNED)';
      if ($o['order'][1] === 2) {
        $order .= ' DESC';
      }
      break;
    default:
      $order = 'p.menu_order, p.ID';
      break;
    }
    # }}}
    # compose database query
    $q = <<<EOD

      SELECT DISTINCT p.ID
      FROM {$this->prefix}posts AS p {$joins}
      WHERE p.post_type = 'product' {$filts}
      ORDER BY {$order}

EOD;
    # query the database
    if (($res = $this->db->query($q)) === false) {
      #$a = mysqli_error($this->db);
      #xdebug_break();
      return null;
    }
    # get the result and cleanup
    $a = $res->fetch_all(MYSQLI_NUM);
    $res->free();
    # flatten result
    $res = [];
    foreach ($a as $b) {
      $res[] = $b[0];
    }
    # done
    return $res;
  }
  # }}}
  public function getProduct($id) # {{{
  {
    # prepare
    $db  = $this->db;
    $wp_ = $this->prefix;
    $res = null;
    # get
    # data {{{
    # assemble a query
    $q = <<<EOD

      SELECT
        post_author   AS author,
        post_date     AS created,
        post_title    AS name,
        post_excerpt  AS excerpt,
        post_status   AS status,
        post_name     AS slug,
        post_modified AS modified,
        post_parent   AS parent,
        menu_order

      FROM {$wp_}posts
      WHERE ID = {$id}

EOD;
    # query the database
    if (($a = $db->query($q)) === false) {
      #$a = mysqli_error($db);
      return null;
    }
    # get the result
    $res = ($a->fetch_all(MYSQLI_ASSOC))[0];
    # cleanup
    $a->free();
    # }}}
    # metadata {{{
    # create a query
    $q = <<<EOD

    (
      SELECT meta_key, meta_value
      FROM {$wp_}postmeta
      WHERE post_id = {$id}
    )
    UNION ALL
    (
      SELECT x.taxonomy, t.name
      FROM {$wp_}term_taxonomy AS x
        JOIN {$wp_}term_relationships AS s
          ON s.term_taxonomy_id = x.term_taxonomy_id
        JOIN {$wp_}terms AS t
          ON t.term_id = x.term_id
      WHERE
        x.taxonomy = 'product_type' AND
        s.object_id = {$id}
    )

EOD;
    # query the database
    if (($a = $db->query($q)) === false) {
      return null;
    }
    # assemble into result
    for ($b = 0; $b < $a->num_rows; ++$b)
    {
      $c = $a->fetch_row();
      $res[$c[0]] = $c[1];
    }
    # cleanup
    $a->free();
    # }}}
    # done
    return $res;
  }
  # }}}
  public function getCategoryTree($root, $hasEmpty) # {{{
  {
    # determine root node identifier
    if (!empty($root))
    {
      # check valid
      if (strlen($root) > 200) {
        return null;
      }
      # determine filter clause
      if (ctype_digit($root)) {
        $root = 'term_id = '.$root;
      }
      else
      {
        $root = $this->db->real_escape_string($root);
        $root = "name = '$root'";
      }
      # create a query expression
      $q = <<<EOD

        SELECT term_id
        FROM {$this->prefix}terms
        WHERE {$root}

EOD;
      # run it
      if (($q = $this->db->query($q)) === false) {
        return null;
      }
      # get the result
      if (!($a = $q->fetch_row()) || count($a) !== 1) {
        return null;
      }
      $root = $a[0];
      # cleanup
      $q->free();
    }
    else {
      $root = 0;
    }
    # extract all product categories,
    # this consumes more memory but works faster..
    # prepare extra filter
    $q = $hasEmpty ? '' : 'AND IFNULL(tmc.meta_value, 0) > 0';
    # create query expression
    $q = <<<EOD

      SELECT
        tm.term_id, tm.name,
        tx.parent,
        tmo.meta_value,
        IFNULL(tmc.meta_value, 0)
      FROM {$this->prefix}term_taxonomy AS tx
        JOIN {$this->prefix}terms AS tm ON tm.term_id = tx.term_id
        LEFT JOIN {$this->prefix}termmeta AS tmo
          ON tmo.term_id  = tx.term_id AND
             tmo.meta_key = 'order'
        LEFT JOIN {$this->prefix}termmeta AS tmc
          ON tmc.term_id  = tx.term_id AND
             tmc.meta_key = 'product_count_product_cat'
      WHERE
        tx.taxonomy = 'product_cat' {$q}
      ORDER BY
        tmo.meta_value, tm.term_id

EOD;
    # run it
    if (($q = $this->db->query($q)) === false) {
      return null;
    }
    # get the result and cleanup
    $a = $q->fetch_all(MYSQLI_NUM);
    $q->free();
    # create items map: [id => item]
    $q = [];
    foreach ($a as $b)
    {
      $q[$b[0]] = [
        'id'    => $b[0],
        'name'  => $b[1],
        'pid'   => $b[2],
        'order' => $b[3],
        'total' => $b[4],
        'count' => $b[4],
        'depth' => 0,
        'list'  => null,
      ];
    }
    # free memory
    unset($a);
    # create root node
    $q[0] = [
      'id'    => 0,
      'name'  => '',
      'pid'   => -1,
      'order' => 0,
      'count' => 0,
      'total' => 0,
      'depth' => 0,
      'list'  => null,
    ];
    # create parents map: [parent => items]
    $p = [];
    foreach ($q as &$a)
    {
      if (($b = $a['pid']) >= 0)
      {
        # create a list
        if (!array_key_exists($b, $p)) {
          $p[$b] = [];
        }
        # add item
        $p[$b][] = &$a;
      }
    }
    unset($a);
    # create recursive helper
    $f = function(&$item, $depth) use (&$f, $q, $p)
    {
      # set depth
      $item['depth'] = $depth;
      # check item is a parent
      $a = $item['id'];
      if (array_key_exists($a, $p))
      {
        # set children
        $item['list'] = &$p[$a];
        # recurse to determine own items count
        $a = $item['count'];
        foreach ($item['list'] as &$a) {
          $item['count'] -= $f($a, $depth + 1);
        }
      }
      return $item['total'];
    };
    # initialize relationships
    $f($q[$root], 0);
    # done
    return $q[$root];
  }
  # }}}
  public function getCurrency() # {{{
  {
    # get currency settings (secret woo funcs :/)
    $a = [
      html_entity_decode(get_woocommerce_currency_symbol(), ENT_HTML5, 'UTF-8'),
      wc_get_price_decimal_separator(),
      wc_get_price_thousand_separator(),
      wc_get_price_decimals(),
    ];
    # add simbol position
    $b   = get_option('woocommerce_currency_pos');
    $a[] = (strpos($b, 'right') === 0);
    # done
    return $a;
  }
  # }}}
  public function getCart() # {{{
  {
    global $woocommerce;
    ###
    return $woocommerce->cart->get_cart_contents();
  }
  # }}}
  public function setCart($id) # {{{
  {
    global $woocommerce;
    ###
    # invoke woo
    if (!($cid = $woocommerce->cart->add_to_cart($id))) {
      return false;
    }
    # done
    return $cid;
  }
  # }}}
  # TODO
  private function purgeCache()
  {
    # delete cache files
    foreach (glob($this->dir_data.'*.tmp') as $a) {
      unlink($a);
    }
  }
  # }}}
}
function_exists('register_activation_hook') && register_activation_hook(__FILE__, function() {
  # {{{
  # check/activate woocommerce plugin
  if (!class_exists('WooCommerce', false))
  {
    $a = 'woocommerce';
    $a = activate_plugin($a.DIRECTORY_SEPARATOR.$a.'.php');
  }
  # }}}
});
function_exists('add_action') && add_action('plugins_loaded', function() {
  # {{{
  if (class_exists('WooCommerce', false)) {
    StorefrontModernBlocks::init();
  }
  # }}}
});
?>
