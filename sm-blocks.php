<?php
/***
* Plugin Name: sm-blocks
* Description: A fully-asynchronous e-commerce catalogue
* Plugin URI: github.com/determin1st/sm-blocks
* Author: determin1st
* Version: 1
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
    $unique_id = 0,
    $dir_data  = __DIR__.DIRECTORY_SEPARATOR.'data'.DIRECTORY_SEPARATOR,
    $dir_inc   = __DIR__.DIRECTORY_SEPARATOR.'inc'.DIRECTORY_SEPARATOR,
    $base_attr = [
      'customClass',
      'class',
      'style',
    ],
    $blocks    = [
      'products' => [ # {{{
        'render_callback' => [null, 'renderProducts'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          ### grid dimensions
          'layout'        => [
            'type'        => 'string',
            'default'     => '4:2:1:0',# [maxColumns:minRows:minColumns:maxRows]
          ],
          'itemSize'     => [
            'type'        => 'string',
            'default'     => '0:0',# [width:height]
          ],
          ### records ordering
          'options'  => [
            'type'        => 'array',
            'default'     => ['featured','new','price'],
          ],
          'order'         => [
            'type'        => 'array',
            'default'     => ['price',1],
          ],
          'wrapAround'    => [
            'type'        => 'boolean',
            'default'     => true,
          ],
        ],
      ],
      # }}}
      'rows-selector' => [ # {{{
        'render_callback' => [null, 'renderBase'],
        'attributes'      => [
          ###
          ###
          'list'          => [
            'type'        => 'array',
            'default'     => [0,2,4,8,16], # 0=auto
          ],
          'index'         => [
            'type'        => 'number',
            'default'     => 1,
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
          'focusGreedy'   => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          ### controls
          'rangeMode'     => [
            'type'        => 'number',
            'default'     => 2, # 0=none,1=static,2=flexy
          ],
          'rangeSize'     => [
            'type'        => 'string',
            'default'     => '1:2', # pages before:after current
          ],
          'gotoMode'      => [
            'type'        => 'number',
            'default'     => 1|2|4, # 0=none|1=separators|2=prev/next|4=first/last
          ],
        ],
      ],
      # }}}
      'orderer' => [ # {{{
        'render_callback' => [null, 'renderBase'],
        'attributes'      => [
          ### common
          'customClass'   => [
            'type'        => 'string',
            'default'     => 'custom',
          ],
          ###
          'order'         => [
            'type'        => 'array',
            'default'     => ['featured',-1],
          ],
          'switchMode'    => [
            'type'        => 'number',
            'default'     => 1,
          ],
          'autodrop'      => [
            'type'        => 'boolean',
            'default'     => false,
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
          'focusGreedy'   => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          'sectionMode'   => [
            'type'        => 'number',
            'default'     => 1|2|4,
          ],
          ### specific
          'sectionSwitch' => [
            'type'        => 'boolean',
            'default'     => true,
          ],
          'sliceGroups'   => [
            'type'        => 'number',
            'default'     => 0,
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
          'focusGreedy'   => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          ### section
          'sectionMode'   => [
            'type'        => 'number',
            'default'     => 1|2|4,
          ],
          'sectionOpened' => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          ### specific
          'baseCategory'  => [
            'type'        => 'string',
            'default'     => '',
          ],
          'operator'      => [
            'type'        => 'string',
            'default'     => 'OR',
          ],
          'hasEmpty'      => [
            'type'        => 'boolean',
            'default'     => false,
          ],
          'hasCount'      => [
            'type'        => 'boolean',
            'default'     => false,
          ],
        ],
      ],
      # }}}
    ],
    $templates = [
      'base' => [ # {{{
        'root' => '
        <div class="{{name}}">
          <div class="{{class}}" style="{{style}}" data-cfg=\'{{cfg}}\'></div>
          {{placeholder}}
        </div>
        ',
      ],
      # }}}
      'products' => [ # {{{
        'main' => '
        <div class="sm-blocks products {{custom}}" style="{{style}}">
          <div data-cfg=\'{{cfg}}\'></div>
          {{placeholder}}
          <hr>
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
      'paginator' => [ # {{{
        'main' => '
        <div class="sm-blocks paginator {{custom}}">
          <div data-cfg=\'{{cfg}}\'>
            {{gotoF}}{{gotoP}}{{sep1}}{{range}}{{sep2}}{{gotoN}}{{gotoL}}
          </div>
          {{placeholder}}
        </div>
        ',
        'range' => '
        <div class="range">
          {{page}}{{gap}}{{pages}}{{gap}}{{page}}
        </div>
        ',
        'page' => '
        <div class="sm-buttons page"><button type="button"></button></div>
        ',
        'sep1' => '
        <div class="sep L">
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path d="M3 .997h6v14H3zM10 1.997h3v12h-3z"/>
        </svg>
        </div>
        ',
        'sep2' => '
        <div class="sep R">
        <svg preserveAspectRatio="none" viewBox="0 0 16 16">
          <path d="M7 .997h6v14H7zM3 1.997h3v12H3z"/>
        </svg>
        </div>
        ',
        'gotoF' => '
        <div class="sm-buttons goto FL F">
        <button type="button">
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M58.644 27.26v8.294c0 .571-.305 1.1-.8 1.385L37.632 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L16.869 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
          <path d="M57.844 63.048l-2.376-1.372c-.013.043-.023.09-.032.136l.409.236c.495.286.8.814.8 1.385v8.294c0 1.008-.894 1.693-1.803 1.575l1.404.81a1.6 1.6 0 002.399-1.385v-8.294a1.603 1.603 0 00-.801-1.385zM37.632 48.608l20.212-11.669a1.6 1.6 0 00.8-1.385V27.26c0-1.115-1.092-1.84-2.091-1.512.054.16.091.328.091.512v8.294c0 .571-.305 1.1-.8 1.385L35.632 47.608c-.078.052-.745.516-.8 1.385-.057.911.609 1.467.673 1.518l1.916 1.328a.747.747 0 01.019-.51.575.575 0 01.037-.07c-.895-.672-.852-2.069.155-2.651z"/>
          <path fill="none" stroke-miterlimit="10" d="M58.644 27.26v8.294c0 .571-.305 1.1-.8 1.385L37.632 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L16.869 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
          <path d="M86.058 27.26v8.294c0 .571-.305 1.1-.8 1.385L65.047 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L44.283 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
          <path d="M85.258 63.048l-2.376-1.372c-.013.043-.023.09-.032.136l.409.236c.495.286.8.814.8 1.385v8.294c0 1.008-.894 1.693-1.803 1.575l1.404.81a1.6 1.6 0 002.399-1.385v-8.294a1.603 1.603 0 00-.801-1.385zM65.047 48.608l20.212-11.669a1.6 1.6 0 00.8-1.385V27.26c0-1.115-1.092-1.84-2.091-1.512.054.16.091.328.091.512v8.294c0 .571-.305 1.1-.8 1.385L63.047 47.608c-.078.052-.745.516-.8 1.385-.057.911.609 1.467.673 1.518l1.916 1.328a.747.747 0 01.019-.51.575.575 0 01.037-.07c-.896-.672-.853-2.069.155-2.651z"/>
          <path fill="none" stroke-miterlimit="10" d="M86.058 27.26v8.294c0 .571-.305 1.1-.8 1.385L65.047 48.608a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L44.283 51.379a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.4 1.385z"/>
        </svg>
        </button>
        </div>
        ',
        'gotoL' => '
        <div class="sm-buttons goto FL L">
        <button type="button">
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M41.762 27.26v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L42.562 63.048a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L44.161 25.875a1.6 1.6 0 00-2.399 1.385z"/>
          <path d="M83.537 48.608L44.161 25.875a1.56 1.56 0 00-.597-.19l37.972 21.923a1.6 1.6 0 010 2.771L42.161 73.112c-.1.058-.205.092-.308.126.308.914 1.401 1.398 2.308.874l39.375-22.733a1.6 1.6 0 00.001-2.771z"/>
          <path fill="none" stroke-miterlimit="10" d="M41.762 27.26v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L42.562 63.048a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L44.161 25.875a1.6 1.6 0 00-2.399 1.385z"/>
          <path d="M14.664 27.273v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L15.464 63.061a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L17.063 25.888a1.6 1.6 0 00-2.399 1.385z"/>
          <path d="M56.438 48.621L17.063 25.888a1.56 1.56 0 00-.597-.19l37.972 21.923a1.6 1.6 0 010 2.771L15.063 73.125c-.1.058-.205.092-.308.126.308.914 1.401 1.398 2.308.874l39.375-22.733a1.6 1.6 0 000-2.771z"/>
          <path fill="none" stroke-miterlimit="10" d="M14.664 27.273v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L15.464 63.061a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L17.063 25.888a1.6 1.6 0 00-2.399 1.385z"/>
        </svg>
        </button>
        </div>
        ',
        'gotoP' => '
        <div class="sm-buttons goto PN P">
        <button type="button">
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M70.787 27.267v8.294c0 .571-.305 1.1-.8 1.385L49.776 48.615a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L29.013 51.385a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.399 1.386z"/>
          <path d="M69.987 63.055l-2.376-1.372c-.013.043-.023.09-.032.136l.409.236c.495.286.8.814.8 1.385v8.294c0 1.008-.894 1.693-1.803 1.575l1.404.81a1.6 1.6 0 002.399-1.385V64.44a1.6 1.6 0 00-.801-1.385zM49.776 48.615l20.212-11.669a1.6 1.6 0 00.8-1.385v-8.294c0-1.115-1.092-1.84-2.091-1.512.054.16.091.328.091.512v8.294c0 .571-.305 1.1-.8 1.385L47.776 47.615c-.078.052-.745.516-.8 1.385-.057.911.609 1.467.673 1.518l1.916 1.328a.747.747 0 01.019-.51.575.575 0 01.037-.07c-.896-.673-.853-2.07.155-2.651z"/>
          <path fill="none" stroke-miterlimit="10" d="M70.787 27.267v8.294c0 .571-.305 1.1-.8 1.385L49.776 48.615a1.6 1.6 0 000 2.771l20.212 11.669c.495.286.8.814.8 1.385v8.294a1.6 1.6 0 01-2.399 1.385L29.013 51.385a1.6 1.6 0 010-2.771l39.375-22.733a1.6 1.6 0 012.399 1.386z"/>
        </svg>
        </button>
        </div>
        ',
        'gotoN' => '
        <div class="sm-buttons goto PN N">
        <button type="button">
        <svg preserveAspectRatio="none" viewBox="0 0 100 100">
          <path d="M28.213 27.267v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L29.013 63.055a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L30.612 25.881a1.6 1.6 0 00-2.399 1.386z"/>
          <path d="M69.987 48.615L30.612 25.881a1.56 1.56 0 00-.597-.19l37.972 21.923a1.6 1.6 0 010 2.771L28.612 73.119c-.1.058-.205.092-.308.126.308.914 1.401 1.398 2.308.874l39.375-22.733a1.6 1.6 0 000-2.771z"/>
          <path fill="none" stroke-miterlimit="10" d="M28.213 27.267v8.294c0 .571.305 1.1.8 1.385l20.212 11.669a1.6 1.6 0 010 2.771L29.013 63.055a1.6 1.6 0 00-.8 1.385v8.294a1.6 1.6 0 002.399 1.385l39.375-22.733a1.6 1.6 0 000-2.771L30.612 25.881a1.6 1.6 0 00-2.399 1.386z"/>
        </svg>
        </button>
        </div>
        ',
        ###
        'gap-static' => '
        <div class="gap">
        <svg preserveAspectRatio="none" viewBox="0 0 48 48">
          <path d="M1 41h14v6H1zM17 41h14v6H17zM33 41h14v6H33z"/>
        </svg>
        </div>
        ',
        'gap-flexy' => '
        <div class="gap">
        <svg preserveAspectRatio="none" viewBox="0 0 48 48">
          <rect y="4" width="48" height="40"/>
        </svg>
        </div>
        ',
      ],
      # }}}
      'price-filter' => [ # {{{
        'root' => '
        <div>
          <div class="L">
            <input id="{{UID=1}}"
                   type="text" inputmode="numeric"
                   pattern="[0-9]*"
                   maxlength="9" readonly>
            <label for="{{UID=1}}"></label>
          </div>
          {{delimiter}}
          <div class="R">
            <input id="{{UID=2}}"
                   type="text" inputmode="numeric"
                   pattern="[0-9]*"
                   maxlength="9" readonly>
            <label for="{{UID=2}}"></label>
          </div>
        </div>
        ',
        'delimiter' => '
        <svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
          <polygon points="0,48 4,48 12,43 18,41 22,40 26,40 30,41 36,43 44,48 48,48 48,0 44,0 36,5 30,7 26,8 22,8 18,7 12,5 4,0 0,0 "/>
          <polygon class="L" points="13,28 16,31 19,32 23,32 23,31 19,30 17,28 16,24 17,20 19,18 23,17 23,16 19,16 16,17 13,20 12,22 12,26 "/>
          <polygon class="X" points="18,28 20,30 24,31 28,30 30,28 31,24 30,20 28,18 24,17 20,18 18,20 17,24 "/>
          <polygon class="R" points="35,28 32,31 29,32 25,32 25,31 29,30 31,28 32,24 31,20 29,18 25,17 25,16 29,16 32,17 35,20 36,22 36,26 "/>
        </svg>
        ',
      ],
      # }}}
      'section' => [ # {{{
        'main' => '
        <div class="sm-blocks section {{custom}}">
          <div class="item" data-cfg=\'{{cfg}}\'>
            {{title}}{{sep}}{{section}}
          </div>
          {{placeholder}}
        </div>
        ',
        'item' => '
        <div class="item" data-cfg=\'{{cfg}}\'>
          {{title}}{{section}}
        </div>
        ',
        'title' => '
        <div class="title">
          <div>
            <h3><label></label></h3>
            <button type="button" class="arrow">{{arrowIcon}}</button>
          </div>
        </div>
        ',
        'section' => '
        <div class="section">{{items}}</div>
        ',
        'arrowIcon' => '
        <svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
          <polygon class="a" points="24,44 1,4 47,4 "/>
          <polygon class="b" points="24,40 5,6 43,6 "/>
        </svg>
        ',
        'sep' => '
        <svg class="sep" preserveAspectRatio="none" viewBox="0 0 200 5">
          <polygon points="2,0 6,0 8,1 192,1 194,0 198,0 200,4 200,5 0,5 0,4 "/>
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
    $cache     = [
      'categoryTree' => [], # key  => tree
      'categorySlug' => [], # slug => id
    ];
  # }}}
  # construction {{{
  private function __construct()
  {
    global $wpdb;
    # prepare
    $this->db     = $wpdb->dbh;
    $this->prefix = $wpdb->prefix;
    $this->lang   = substr(get_locale(), 0, 2);
    # initialize block renderers
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
    # register styles and scripts
    wp_register_style(
      $this->name.'-css',
      $a.'inc/'.$this->name.'.css'
    );
    wp_register_style(
      $this->name.'-demo-css',
      $a.'inc/pages/demo.css'
    );
    wp_register_script(
      $this->name.'-js',
      $a.'inc/'.$this->name.'.js',
      ['http-fetch'],
      false, true
    );
    /***
    wp_register_script(
      $this->name.'-gutenberg-js',
      $a.'inc/'.$this->name.'-gutenberg.js',
      [
        'wp-blocks', 'wp-element',
        'wp-editor', 'wp-components'
      ],
      false, true
    );
    /***/
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
        'callback' => [$me, 'apiEntry'],
      ]);
    });
    add_action('enqueue_block_assets', function() use ($me) {
      if (is_admin())
      {
        #wp_enqueue_script($me->name.'-gutenberg-js');
      }
      else if (is_shop())
      {
        wp_enqueue_style($me->name.'-css');
        wp_enqueue_script($me->name.'-js');
        wp_enqueue_style($me->name.'-demo-css');
        # remove gutenberg's default/core blocks:
        #wp_dequeue_style('wp-block-library');
        #wp_deregister_style('wp-block-library');
      }
    });
    add_action('wp_enqueue_scripts', function() use ($me) {
      # make sure base woo's on
      if (is_shop()) {
        #wp_dequeue_style('woocommerce-general');
        #wp_enqueue_style(
        #  'woocommerce-sm', WC()->plugin_url().'/assets/css/woocommerce.css'
        #);
      }
    }, 11);
    # set shop template
    add_filter('template_include', function($t) use ($me) {
      return is_shop()
        ? $me->dir_inc.'pages'.DIRECTORY_SEPARATOR.'demo.php'
        : $t;
      ###
    }, 11, 1);
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
  # csr rendering
  # base {{{
  public function renderBase($attr, $content, $block)
  {
    # prepare
    $T = $this->templates['base'];
    ###
    $name = str_replace('/', ' ', $block->name);
    if (array_key_exists('customClass', $attr) && ($a = $attr['customClass'])) {
      $name = $name.' '.$a;
    }
    else {
      $name = $name.' custom';
    }
    ###
    $class = (array_key_exists('class', $attr) && $attr['class'])
      ? $attr['class'] : '';
    $style = (array_key_exists('style', $attr) && $attr['style'])
      ? $attr['style'] : '';
    ###
    $cfg = [];
    foreach ($attr as $a => $b)
    {
      if (!in_array($a, $this->base_attr)) {
        $cfg[$a] = $b;
      }
    }
    $cfg = json_encode($cfg, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
    # compose
    return $this->parseTemplate($T['root'], $T, [
      'name'   => $name,
      'class'  => $class,
      'style'  => $style,
      'cfg'    => $cfg,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # ssr rendering
  # products {{{
  public function renderProducts($attr, $content)
  {
    # prepare
    $T = $this->templates['products'];
    $layout = explode(':', $attr['layout']);
    foreach ($layout as &$a) {
      $a = intval($a);
    }
    unset($a);
    # determine grid style
    $style = "--columns:{$layout[0]};--rows:{$layout[1]};";
    if (($a = $attr['itemSize']) && strlen($a) > 2)
    {
      $a = explode(':', $a);
      if (($b = intval($a[0])) > 0) {
        $style .= "--item-width:{$b}px;";
      }
      if (($b = intval($a[1])) > 0) {
        $style .= "--item-height:{$b}px;";
      }
    }
    # compose
    return $this->parseTemplate($T['main'], $T, [
      'custom' => $attr['customClass'],
      'style'  => $style,
      'cfg'    => json_encode([
        'layout'  => $layout,
        'order'   => $attr['order'],
        'options' => $attr['options'],
        'wrapAround' => $attr['wrapAround'],
      ]),
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # paginator {{{
  public function renderPaginator($attr, $content)
  {
    # prepare
    $T = $this->templates['paginator'];
    # refine parameters
    $a = explode(':', $attr['rangeSize']);
    $rangeIndex = intval($a[0]);
    $rangeSize  = $rangeIndex + intval($a[1]) + 1;
    $gotoFL  = !!($attr['gotoMode'] & 4);
    $gotoPN  = !!($attr['gotoMode'] & 2);
    $gotoSep = !!($attr['gotoMode'] & 1);
    # determine gap
    $gap = $attr['rangeMode'] === 2
      ? $T['gap-flexy']
      : $T['gap-static'];
    # create range
    $pages = '';
    if ($attr['rangeMode'] > 0)
    {
      $a = -1;
      while (++$a < $rangeSize) {
        $pages .= $T['page'];
      }
    }
    # create configuration
    $cfg = json_encode([
      'goto'  => $attr['gotoMode'],
      'range' => $attr['rangeMode'],
      'index' => $rangeIndex,
    ]);
    # compose
    return $this->parseTemplate($T['main'], $T, [
      'custom' => $attr['customClass'],
      'cfg'    => $cfg,
      'gotoF'  => $gotoFL,
      'gotoP'  => $gotoPN,
      'sep1'   => $gotoSep,
      'gap'    => $gap,
      'pages'  => $pages,
      'sep2'   => $gotoSep,
      'gotoN'  => $gotoPN,
      'gotoL'  => $gotoFL,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  # }}}
  # price-filter {{{
  public function renderPriceFilter($attr, $content)
  {
    # prepare
    $T = $this->templates['price-filter'];
    # compose
    return $this->renderSection([
      'custom'    => trim('price-filter '.$attr['customClass']),
      'cfg'       => [
        'sectionSwitch' => $attr['sectionSwitch'],
      ],
      'mode'      => $attr['sectionMode'],
      'autofocus' => $attr['focusGreedy'],
      'items'     => $this->parseTemplate($T['root'], $T, []),
      'opened'    => true,
    ]);
  }
  # }}}
  # category-filter {{{
  public function renderCategoryFilter($attr, $content)
  {
    # get content
    $content = $this->db_CategoryTree(
      $attr['baseCategory'],
      $attr['hasEmpty']
    );
    # create a section
    return $this->renderSection([
      'custom'    => trim('category-filter '.$attr['customClass']),
      'mode'      => $attr['sectionMode'],
      'autofocus' => $attr['focusGreedy'],
      'items'     => $content,
      'opened'    => $attr['sectionOpened'],
    ]);
  }
  private function renderSection($attr)
  {
    # preapre
    $T = $this->templates['section'];
    # determine main section parameters
    $mode    = $attr['mode'];
    $content = $attr['items'];
    $custom  = !!$attr['custom']
      ? $attr['custom']
      : 'custom';
    # check items
    if (is_array($content))
    {
      # fantom root section
      $id = $content['id'];
      $content = $this->renderSectionItem($content, $T, $attr);
    }
    else
    {
      # zero section (foreign content)
      $id = -1;
    }
    # determine root configuration
    $config = !!$attr['cfg']
      ? $attr['cfg']
      : [];
    $config = json_encode(array_merge($config, [
      'mode'   => $mode,
      'id'     => $id,
      'arrow'  => !!($mode &  4), # allow to open/close
      'opened' => !!($mode &  1), # section opened/closed
      'autofocus' => $attr['autofocus'],
    ]));
    # compose
    return $this->parseTemplate($T['main'], $T, [
      'custom' => $custom,
      'cfg'    => $config,
      'items'  => $content,
      'placeholder' => $this->templates['svg']['placeholder'],
    ]);
  }
  private function renderSectionItem($node, $T, $attr)
  {
    # iterate slaves of this master
    $html = '';
    foreach ($node['slaves'] as $a)
    {
      # create configuration
      $b = json_encode([
        'id'     => $a['id'],
        'name'   => $a['name'],
        'depth'  => $a['depth'],
        'arrow'  => $a['arrow'],
        'opened' => false,
        'order'  => $a['order'],
        'count'  => $a['count'],
        'total'  => $a['total'],
      ]);
      # check slave is also a master
      if ($a['slaves'])
      {
        # create section item (recurse)
        $b = $this->parseTemplate($T['item'], $T, [
          'class'   => ($attr['opened'] ? ' o' : ''),
          'cfg'     => $b,
          'section' => true,
          'items'   => $this->renderSectionItem($a, $T, $attr),
        ]);
      }
      else
      {
        # create simple item
        $b = $this->parseTemplate($T['item'], $T, [
          'class'   => '',
          'cfg'     => $b,
          'section' => false,
        ]);
      }
      # aggregate markup
      $html .= $b;
    }
    return $html;
  }
  # }}}
  # rest api
  # kiss entry {{{
  public function apiEntry($p)
  {
    # prepare
    # {{{
    # get parameters
    if (!($p = $p->get_json_params()) || !is_array($p)) {
      $this->apiFail(400, 'incorrect request');
    }
    # check
    $a = [
      'lang','range','order',
      'category','price',
    ];
    foreach ($a as $b) {
      if (!array_key_exists($b, $p)) {
        $this->apiFail(400, 'missing "'.$b.'" parameter');
      }
    }
    # refine parameters
    # language
    $a = $p['lang'];
    if (!is_string($a) || strlen($a) > 2) {
      $this->apiFail(400, 'incorrect language');
    }
    else if (!$a) {
      #$p['lang'] = $this->lang;
      $p['lang'] = 'en';
    }
    # records range
    if ($R = $p['range'])
    {
      if (!is_array($R) || count($R) !== 5) {
        $this->apiFail(400, 'incorrect range');
      }
      for ($a = 0; $a < 5; ++$a)
      {
        if (!array_key_exists($a, $R) || !is_int($R[$a])) {
          $this->apiFail(400, 'incorrect range');
        }
      }
      if ($R[0] <  0 || $R[2] <  0 || $R[4] < 0 ||
          $R[1] < -1 || $R[3] < -1 ||
          ($R[1] === -1 && $R[3] !== -1) ||
          ($R[3] === -1 && $R[1] !== -1) ||
          ($R[1] === -1 && $R[2] !== $R[4]) ||
          ($R[1] === -1 && $R[2] === 0))
      {
        $this->apiFail(400, 'incorrect range');
      }
    }
    # order
    $a = $p['order'];
    if (!is_array($a)     || count($a) !== 2 ||
        !is_string($a[0]) || !is_int($a[1]))
    {
      $p['order'] = null;
    }
    # category filter
    # parsing is not simple, so it's wrapped
    $p['category'] = $this->parseCategoryFilter($p['category']);
    # price filter
    if (!($a = $p['price']))
    {
      # empty parameter is allowed (meaning no filter)
      $p['price'] = null;
    }
    else if (!is_array($a)  || count($a) !== 2 ||
             !is_int($a[0]) || !is_int($a[1]) ||
             $a[0] < -1 || $a[1] < -1 ||
             (~$a[0] && ~$a[1] && $a[0] >= $a[1]))
    {
      # incorrect value and type should be rejected
      $this->apiFail(400, 'incorrect price');
    }
    if ($a[0] === -1 && $a[0] == $a[1])
    {
      # a special case, unlimited range, means no filter
      $p['price'] = null;
    }
    # }}}
    # operate
    if ($R) {
      # data {{{
      # close session
      if (session_status() === PHP_SESSION_ACTIVE) {
        session_write_close();
      }
      # clear output buffer
      while (ob_get_level() !== 0) {
        ob_end_clean();
      }
      # set query parameters (thick)
      $q = [
        'order'    => $p['order'],
        'category' => $p['category'],
        'price'    => $p['price'],
      ];
      # TODO: cache
      # get identifiers
      if (($q = $this->db_Products($q)) === null) {
        $this->apiFail(500, 'failed to get');
      }
      # activate streaming
      header('content-type: application/octet-stream');
      # determine total items count
      $n = count($q);
      # check
      if (!$n || ($R[2] === 0 && $R[4] === 0)) {
        exit;
      }
      # determine proper range
      if ($R[1] === -1) {
        # {{{
        # get maximal range size (equal for both ranges)
        $c = $R[2];
        # get desired offset
        if ($R[0] >= $n) {
          $R[0] = 0;
        }
        # set initial range offsets
        $R[1] = $R[0];
        $R[3] = $R[0] - 1;
        # correct
        # check front overflows N-point
        if (($b = $R[0] + $c - $n - 1) >= 0)
        {
          # front overflows,
          # check back is not at the end
          if (~$R[3])
          {
            # check back overflows 0-point
            if (($d = $R[3] - $c) < 0)
            {
              # back is limited by 0-point
              # front is limited by N-point
              $R[2] = $n - $R[0];
              $R[4] = $R[0];
            }
            else if ($d < $b)
            {
              # front is limited by back
              $R[2] = $c - $b + $d;
            }
          }
          else
          {
            # back is empty
            $R[3] = $n - 1;
            $R[4] = 0;
          }
        }
        else
        {
          # standard front,
          # check back is not at the end
          if (~$R[3])
          {
            # check back overflows 0-point and front end-point
            if (($b = $R[3] - $c) < 0 &&
                ($d = $R[0] + $c - $n - $b - 1) > 0)
            {
              # back is limited by front
              $R[4] = $c - $d;
            }
          }
          else
          {
            # check back overflows front end-point
            $R[3] = $n - 1;
            if (($b = $R[0] + $c - $R[3] + $c) > 0)
            {
              # back is limited by front
              $R[4] = $b - 1;
            }
          }
        }
        # }}}
      }
      # send total
      $this->sendInt($n);
      # send items
      if ($R[2]) {
        # forward range
        $a = $R[1] - 1;
        if (($b = $R[1] + $R[2]) > $n)
        {
          while (++$a < $n) {
            $this->sendJSON($this->db_Product($q[$a], $a));
          }
          $a = -1;
          $b = $b - $n;
        }
        while (++$a < $b) {
          $this->sendJSON($this->db_Product($q[$a], $a));
        }
      }
      if ($R[4]) {
        # backward range (in reversed order)
        $a = $R[3] + 1;
        if (($b = $R[3] - $R[4]) < -1)
        {
          while (--$a >= 0) {
            $this->sendJSON($this->db_Product($q[$a], $a));
          }
          $a = $n;
          $b = $n + $b;
        }
        while (--$a > $b) {
          $this->sendJSON($this->db_Product($q[$a], $a));
        }
      }
      # }}}
    }
    else {
      # configuration {{{
      # get products (thin query)
      $q = [
        'category' => $p['category'],
        'price'    => null,
        'order'    => null,
      ];
      if (($q = $this->db_Products($q)) === null) {
        $this->apiFail(500, 'failed to get');
      }
      # get locale and language
      $locale = __DIR__.DIRECTORY_SEPARATOR.$this->name.'-locale.php';
      $locale = (include $locale);
      $lang   = array_key_exists($p['lang'], $locale)
        ? $p['lang']
        : 'en';
      # encode
      $q = json_encode([
        'lang'      => $lang,
        'locale'    => $locale[$lang],
        'currency'  => $this->db_Currency(),
        'cart'      => $this->db_Cart(),
        'price'     => $this->db_PriceRange($q),
        'total'     => count($q),
      ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
      if ($q === null) {
        $this->apiFail(500, json_last_error_msg());
      }
      # send
      header('content-type: application/json');
      echo $q;
      # }}}
    }
    # done
    exit;
  }
  # }}}
  # helpers {{{
  private function apiCart($request) # {{{
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
  private function apiFail($code, $msg) # {{{
  {
    http_response_code($code);
    header('content-type: text/plain');
    echo $msg;
    flush();
    exit;
  }
  # }}}
  private function sendInt($i) # {{{
  {
    # convert and send as big-endian value
    echo pack('N', $i);
    flush();
    # done
    return true;
  }
  # }}}
  private function sendJSON($o) # {{{
  {
    # create json string
    if (($o = json_encode($o)) === false) {
      return false;
    }
    # send size
    echo pack('N', strlen($o));
    # send content
    echo $o;
    # done
    flush();
    return true;
  }
  # }}}
  # }}}
  # model
  # database {{{
  private function db_Products($o) # {{{
  {
    # prepare
    # determine filters {{{
    $joins = $filts = '';
    if (!!($a = $o['category']) && count($a) > 0)
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
        $filts .=
          'AND tCatRel.term_taxonomy_id IN ('.
          implode(',', $b).') ';
      }
    }
    if ($a = $o['price'])
    {
      $joins .= <<<EOD
        LEFT JOIN {$this->prefix}postmeta as mPrice
          ON mPrice.post_id  = p.ID AND
             mPrice.meta_key = '_price'
EOD;
      if (~$a[0]) {
        $filts .= 'AND CAST(mPrice.meta_value AS SIGNED) >= '.$a[0].' ';
      }
      if (~$a[1]) {
        $filts .= 'AND CAST(mPrice.meta_value AS SIGNED) < '.$a[1].' ';
      }
    }
    # }}}
    # determine order {{{
    # default
    $order = 'p.menu_order, p.ID';
    # specific
    if ($o['order'])
    {
      if ($o['order'][0] === 'featured')
      {
        $joins .= <<<EOD
          LEFT JOIN {$this->prefix}terms as tFeatured
            ON tFeatured.name = 'featured'
          LEFT JOIN {$this->prefix}term_relationships as tFeatRel
            ON tFeatRel.term_taxonomy_id = tFeatured.term_id AND
              tFeatRel.object_id = p.ID
EOD;
        $order = 'tFeatRel.term_taxonomy_id DESC, p.menu_order, p.post_title';
      }
      else if ($o['order'][0] === 'new')
      {
        $order = 'p.post_date DESC, p.post_title';
      }
      else if ($o['order'][0] === 'price')
      {
        # add joins only if required
        if (!$o['price'])
        {
          $joins .= <<<EOD
            LEFT JOIN {$this->prefix}postmeta as mPrice
              ON mPrice.post_id  = p.ID AND
                mPrice.meta_key = '_price'
EOD;
        }
        $order = ($o['order'][1] === 1)
          ? ' DESC'
          : '';
        $order = 'CAST(mPrice.meta_value AS SIGNED)'.$order;
      }
    }
    # }}}
    # compose
    $q = <<<EOD

      SELECT DISTINCT p.ID
      FROM {$this->prefix}posts AS p {$joins}
      WHERE p.post_type = 'product' {$filts}
      ORDER BY {$order}

EOD;
    # query the database
    if (($res = $this->db->query($q)) === false) {
      $a = mysqli_error($this->db);
      print_r($q);
      print_r($a);
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
  private function db_PriceRange($ids) # {{{
  {
    # prepare
    $ids = implode(',', $ids);
    $wp  = $this->prefix;
    # compose query
    $q = <<<EOD

      SELECT
        MIN(CAST(m.meta_value AS SIGNED)),
        MAX(CAST(m.meta_value AS SIGNED))
      FROM {$wp}posts AS p
        JOIN {$wp}postmeta AS m
          ON m.meta_key = '_price' AND
             m.post_id = p.ID
      WHERE
        p.ID IN ({$ids})

EOD;
    # execute
    if (($q = $this->db->query($q)) === false) {
      return [0,1];
    }
    # get the result and cleanup
    $a = $q->fetch_all(MYSQLI_NUM);
    $q->free();
    # check
    if (count($a) !== 1) {
      return [0,1];
    }
    # correct
    $a = $a[0];
    if (($a[0] = intval($a[0])) < 0) {
      $a[0] = 0;
    }
    if (($a[1] = intval($a[1]) + 1) < 1) {
      $a[1] = 1;
    }
    # done
    return $a;
  }
  # }}}
  private function db_Currency() # {{{
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
  private function db_Cart() # {{{
  {
    global $woocommerce;
    return $woocommerce->cart->get_cart_contents();
  }
  # }}}
  private function db_Product($id, $index) # {{{
  {
    # prepare
    $db  = $this->db;
    $wp_ = $this->prefix;
    $x   = null;
    # get posts {{{
    # assemble a query
    $q = <<<EOD

      SELECT
        post_author   AS author,
        post_date     AS created,
        post_title    AS title,
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
      return null;
    }
    # get the result
    $x = ($a->fetch_all(MYSQLI_ASSOC))[0];
    # cleanup
    $a->free();
    # }}}
    # get metadata {{{
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
      $x[$c[0]] = $c[1];
    }
    # cleanup
    $a->free();
    # }}}
    # create transferable item
    $a = [
      'id'    => $id,
      'index' => $index,
      'title' => $x['title'],
      'type'  => $x['product_type'],
      'link'  => get_permalink($id),
      'image' => null,
      'price' => null,
      'stock' => [
        'status'    => $x['_stock_status'],
        'backorder' => $x['_backorders'],
        'count'     => (($x['_stock'] !== null)
          ? intval($x['_stock'])
          : null
        ),
      ],
    ];
    # get image
    if (array_key_exists('_thumbnail_id', $x) &&
        ($b = $x['_thumbnail_id']) && !empty($b) &&
        ($c = wp_get_attachment_url($b)))
    {
      $a['image'] = ['src' => $c];
      if ($b = wp_get_attachment_image_srcset($b, 'full')) {
        $a['image']['srcset'] = $b;
      }
    }
    # get price (TODO: other types)
    switch ($a['type']) {
    case 'simple':
      $a['price'] = [$x['_regular_price'], $x['_price']];
      break;
    }
    return $a;
  }
  # }}}
  private function db_CategoryTree($root, $hasEmpty) # {{{
  {
    # determine root identifier
    # {{{
    if (!empty($root))
    {
      # check valid
      if (strlen($root) > 200) {
        return null;
      }
      # check type
      if (ctype_digit($root))
      {
        # check exact identifier
        if (($root = intval($root)) < 0) {
          return null;
        }
      }
      else
      {
        # check instance cache
        if (!array_key_exists($root, $this->cache['categorySlug']))
        {
          # search by slug
          # create a query
          $q = $this->db->real_escape_string($root);
          $q = <<<EOD

            SELECT term_id
            FROM {$this->prefix}terms
            WHERE slug = '{$q}'

EOD;
          # execute
          if (($q = $this->db->query($q)) === false) {
            return null;
          }
          # checkout the result
          if (!($a = $q->fetch_row()) || count($a) !== 1) {
            return null;
          }
          # cleanup
          $q->free();
          # set cache
          $this->cache['categorySlug'][$root] = $a[0];
        }
        # get from cache
        $root = $this->cache['categorySlug'][$root];
      }
    }
    else {
      $root = 0;
    }
    # convert to string
    $root = ''.$root;
    # }}}
    # check instance cache
    $k = ($hasEmpty ? '1-' : '0-').$root;
    if (!array_key_exists($k, $this->cache['categoryTree'])) {
      # query categories {{{
      # create a query
      $q = $hasEmpty
        ? ''
        : 'AND CAST(tmc.meta_value AS UNSIGNED) > 0';
      $q = <<<EOD

        SELECT
          tm.term_id,
          tm.name,
          tx.parent,
          CAST(tmo.meta_value AS UNSIGNED) AS t_order,
          tmc.meta_value
        FROM {$this->prefix}term_taxonomy AS tx
          JOIN {$this->prefix}terms AS tm
            ON tm.term_id = tx.term_id
          LEFT JOIN {$this->prefix}termmeta AS tmo
            ON tmo.term_id  = tx.term_id AND
              tmo.meta_key = 'order'
          LEFT JOIN {$this->prefix}termmeta AS tmc
            ON tmc.term_id  = tx.term_id AND
              tmc.meta_key = 'product_count_product_cat'
        WHERE
          tx.taxonomy = 'product_cat' {$q}
        ORDER BY
          t_order, tm.name

EOD;
      # execute
      if (($q = $this->db->query($q)) === false) {
        #$a = mysqli_error($this->db);
        return null;
      }
      # get the result and cleanup
      $a = $q->fetch_all(MYSQLI_NUM);
      $q->free();
      # }}}
      # build a tree {{{
      # collect all items into map: [id => item]
      $q = [];
      foreach ($a as $b)
      {
        $q[$b[0]] = [
          'id'     => intval($b[0]),
          'name'   => $b[1],
          'master' => intval($b[2]),
          'depth'  => 0,
          'arrow'  => true,
          'order'  => $b[3] === null ? 0 : intval($b[3]),
          'count'  => intval($b[4]),
          'total'  => intval($b[4]),
          'slaves' => null,
        ];
      }
      unset($a);
      # add fantom master node
      $q[0] = [
        'id'     => 0,
        'name'   => '',
        'master' => -1,
        'depth'  => 0,
        'arrow'  => true,
        'order'  => 0,
        'count'  => 0,
        'total'  => 0,
        'slaves' => null,
      ];
      # create slave items map: [master_id => slave]
      $p = [];
      foreach ($q as &$a)
      {
        # skip fantom master
        if (($b = $a['master']) !== -1)
        {
          # create a master entry
          $b = ''.$b;
          if (!array_key_exists($b, $p)) {
            $p[$b] = [];
          }
          # add slave
          $p[$b][] = &$a;
        }
      }
      unset($a);
      # create recursive helper
      $f = function(&$item, $depth) use (&$f, $q, $p)
      {
        # set depth
        $item['depth'] = $depth;
        # check
        $a = ''.$item['id'];
        if (array_key_exists($a, $p))
        {
          # set slaves
          $item['slaves'] = &$p[$a];
          # recurse to determine own count
          foreach ($item['slaves'] as &$a) {
            $item['count'] -= $f($a, $depth + 1);
          }
          unset($a);
        }
        else
        {
          # no slaves, clear arrow
          $item['arrow'] = false;
        }
        return $item['total'];
      };
      # set relationships
      $f($q[$root], 0);
      # set cache
      $this->cache['categoryTree'][$k] = &$q[$root];
      # }}}
    }
    # done
    return $this->cache['categoryTree'][$k];
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
  # }}}
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
            $b = $attr[$a][$depth];// follow the sequence
          }
          else if (!is_bool($attr[$a])) {
            $b = $attr[$a];// as is (string)
          }
          else if (!$attr[$a]) {
            $b = '';// empty flagged
          }
        }
        else
        {
          # check special
          switch(substr($a, 0, 4)) {
          case 'UID=':
            ++$this->unique_id;
            $attr[$a] = $b = $this->name.'-'.$this->unique_id;
            break;
          }
        }
        # check data
        if ($b === null && array_key_exists($a, $data)) {
          $b = $data[$a];// may be null to save the marker
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
  private function parseCategoryFilter($s)
  {
    # check type
    if (!is_array($s)) {
      return null;
    }
    # check empty
    if (($a = count($s)) === 0) {
      return [];
    }
    # restrict AND operator (count of filters)
    if ($a > 10) {
      return null;
    }
    # prepare
    $F = [];
    $I = 0;
    # refine values
    foreach ($s as $a)
    {
      # check item type
      if (!is_array($a)) {
        return null;
      }
      # check empty
      if (($c = count($a)) === 0) {
        continue;
      }
      # create an entry
      $F[$I] = [];
      # restrict OR operator (check list size)
      if (($I === 0 && $c > 2000) ||
          ($I !== 0 && $c > 100))
      {
        return null;
      }
      # iterate and collect identifiers
      $b = -1;
      while (++$b < $c)
      {
        # check type
        if (!is_int($a[$b]) || $a[$b] < 0) {
          return null;
        }
        # collect unique
        if (array_search($a[$b], $F[$I], true) === false) {
          $F[$I][] = $a[$b];
        }
      }
      # continue
      ++$I;
    }
    return $F;
  }
  # }}}
}
# hooks (wp) {{{
function_exists('register_activation_hook') && register_activation_hook(__FILE__, function() {
  # activate woocommerce plugin
  if (!class_exists('WooCommerce', false))
  {
    $a = 'woocommerce';
    $a = activate_plugin($a.DIRECTORY_SEPARATOR.$a.'.php');
  }
});
function_exists('add_action') && add_action('plugins_loaded', function() {
  if (class_exists('WooCommerce', false)) {
    StorefrontModernBlocks::init();
  }
});
# }}}
?>
