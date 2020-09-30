## 2020-09-29/10-03
#### доработки
- групповое изменение размеров строчных блоков:
  - блоки как правило не фиксированы по длине, но у каждого есть
    минимальная длина меньше которой блок не будет отображатся полностью
    (контролы "наезжают" друг на друга, текст урезается до нечитабельности и пр)
  - при достижении минимальной длины блок может прибегнуть к уменьшению
    своей ширины, эта регулировка пропорций уже реализована для отдельных блоков.
  - в случае нескольких блоков, необходим групповой механизм, так-как
    блоки имеют различные минимальные/начальные размеры. для этого можно
    создать абстрактный блок/объект для группировки и контроля общей ширины.
    (соблюдение общей пропорции, единый размер шрифта и др. элементов)
  - группировка (проблема вложенности и обнаружения):
    - общий предок в иерархии DOM
    - обнаружение выполняет отдельно, каждый блок перебирая предков до корня
    - идентификация объекта выполняется сравнением ноды DOM
    - привязка к группе выполняется запросом к общему контроллеру/блоку
  - контроль (проблема вычисления общей пропорции):
    - инициатор события - блок с измененным (ниже минимума) размером
    - алгоритм поиска и установки оптимальной пропорции - блок контроллер
    - установка через CSS переменную
    - оповещение отсутствует (не требуется)


## 2020-09-22/26
#### доработки
- дополнение: перемещение фокуса при помощи клавишь влево-вправо и вверх-вниз для
  стрелок и галок фильтра категорий
- опция автофокуса блока при наведении курсора.
  (включена по-умолчанию для фильтра категорий и фильтра по цене)


## 2020-09-21
#### статус предыдущей итерации
- рефакторинг фильтра завершен
  - определен предел на количество "AND" фильтров категорий
    (максимум 10 штук на странице),
  - определен предел на размер "OR" списка категорий
    для одного фильрующего блока (максимум 2000).
  - решена проблема с фокусом (см. дополнение)
- исправлен баг при выборе значений в фильтре цены - текущая страница
  в пагинаторе не обновлялась - должна обновлятся только при
  изменении набора элементов в выборке (сброс) и не должна
  обновлятся если те-же товары остались в новом ценовом диапазоне

#### варинты следующей итерации
- продолжить работу над фильтрами категорий
  - наличие фильтра с переключаемыми категориями является
    стандартом UI для "серьезных" ретейл шопиков
- сетка каталога и блок карточки товара
  - наличие кастомных карточек товара является
    необходимым для охвата более широкого круга клиентов


## 2020-09-15/19
#### статус текущей итерации
- рефакторинг фильтра категорий
  - оставить в объекте вложенных секций только обработчики
    скрытия/раскрытия секции
  - убрать весь код связанный с абстрактым объектом секции
    из фильтра
  - переработать в соответствии с этим чекбоксы выбора
    категории и другие структурые добавления в секцию

- вложенные секции это отдельный объект интерфейса для переиспользования,
  на данный момент он используется в:
  - фильтре по цене (секция с одним элементом)
  - фильтре по категориям (вложенные секции)
  - будет использован в других фильтрах с возможностью
    расположения слева-справа в вертикальных панелях, т.к.
    сам элемент интерфейса общеизвестен и традиционно
    применяется в каталогах

#### дополнение
- добавить перемещение фокуса при помощи клавишь влево-вправо и вверх-вниз для:
  - стрелок (стрелка выполняет раскрытие/схлопывание секции)
  - галок (галка помечает элемент выбранным)
- проблема с фокусом, натуральный порядок перемещения не совпадает с
  визуальным во flexbox, т.е. в фильтре категорий галка и стрелка генерируются в
  разметке стрелка/галка, но визуально они галка/стрелка, порядок перемещения
  при нажатии Tab - как в разметке. Нужно либо изменить генерацию разметки,
  либо выполнить отстыковку нужных нод и перестыковать их в нужном порядке
  во фронтенде.



## 2020-09-14
#### статус предыдущей итерации
- фильтр по цене функционален:
  - реализован вариант с двумя текстовыми полями
  - реализовано определение диапазона цен
  - реализованы различные варианты ввода от пользователя (мышь, клавитура, сенсор)
  - все варианты взаимодействий протестированы
- объект секции готов к переиспользованию

#### варинты текущей итерации
- завершить рефакторинг фильтра категорий и
  создать блок выбора категории на основе фильтра категорий,
  аналог "вкладок" или меню:
  - может быть выбрана только одна категория
  - она является активной и подсвечивается
  - уровень блока выше остальных, поэтому выбор "вкладки"
    сбрасывает остальные блоки фильтров и возможно,
    обновляет их содержимое

- завершить рефакторинг сетки каталога и
  создать блок карточки товара:
  - выделить код базовой карточки (то что есть сейчас) из сетки
  - предусмотреть модульность, чтобы можно было расширить
    блок сетки сторонним скриптом.
  - ...

- продолжить работу над фильтром цены
  - округление до сотых, тысячных при прокрутке
  - опция для отключения фильтра при закрытии секции
  - вслывающая панель/кнопка для подтверждения ввода
  - блоки с графиком цен в срезе количества (опция)

- ...


## 2020-09-8/12
#### статус предыдущей итерации
- в следствии того что дополнение заняло часть времени разработки,
  оставшиеся, а также новые выявленные пункты:
  - составной запрос фильтрации (запрос определения границ сделан,
    однако он не должен выполнятся одновременно с фильтром, так-как
    фильтр накладывает конкретное ограничение на диапазон цен).
  - ввод в фильтр (различные варианты ниже)
  - обработка ввода, передача нового запроса и презагрузка каталога
    (взаимодействие блока фильтра с основным блоком)
- таким образом 2 основные задачи:
  - доработка фильтра по цене
  - рефакторинг фильтра категорий
- корректировки по вводу:
  - нажатие Enter в первом текстовом поле (минимум) переводит фокус
    во второе поле (максимум), а нажатие Enter на последнем поле
    приводит к мгновенной перезагрузке каталога с учетом новых данных.
  - необходимо выбрать небольшой timeout если пользователь ввел
    данные но не подтвердил их, а например, перевел фокус на другой
    элемент интерфейса, т.е. контрол потерял фокус но пользователь забыл
    подтвердить изменение. либо нужно сделать сброс на предыдущие значения,
    вариант определится при тестировании.


#### взаимодействие фильтра
- ввод в фильтр цены не сбрасывает ввод в фильтре категорий, однако
  ввод в фильтр категорий может сбрасывать ввод в фильтр цены,
  это опционально для фильтра категорий и по-умолчанию включено.
- ввод в фильр цены сбрасывает ввод в пагинатор
- вводом считается ввод отличного от предыдущего,
  действительного (в рамках min/max) диапазона цены,
  в противном случае устанавливается предыдущий либо максимальный диапазон
- при установке максимально допустимого диапазона фильтр сбрасывается
- запрос определения диапазона цен не совместим запросом фильтра,
  так как логически, при установке фильтра по цене допустимый диапазон будет
  меньше чем заданный фильтр (можно ввести только диапазон меньше),
  исходя из этого, определение границ необходимо выполнять
  БЕЗ УЧЕТА фильтра по цене!
- выполнение запроса на уточнение максимального диапазона проще всего
  реализовать при начальной загрузке (один раз), когда все фильтры сброшены -
  выборка без фильтров однозначно определяет максимально допустимые
  значения для фильтра по цене. (в будущем возможно усложнить это логику)


#### дополнение, фильтр категорий
- после рефакторинга
- дополнительная опция filterMode:
  - (0) дерево с чекобксами, можно выбрать несколько
    вариантов (это то что реализовано сейчас).
    при вводе фильтр цены НЕ СБРАСЫВАЕТСЯ.
  - (1) список с пунктами, можно выбрать только один пункт
    из варинтов узла дерева категорий.
    при вводе фильтр цены СБРАСЫВАЕТСЯ.



## 2020-09-1/5
### фильтр товаров по цене
#### бэкэнд
- цена является общим атрибутом для товаров,
  поэтому необходимо выполнять дополнительный SQL запрос при каждом изменении
  в параметрах выборки для определения границ диапазона. т.е. минимальная цена
  товара (A) в текущей выборке и максимальная (B).

- дополнительный запрос отрабатывает не только при изменении числа товаров, а
  и при любых изменениях в параметрах так как может быть одно и то же число
  товаров в разных категориях.

- для облегчения составного запроса, фронтенд должен передавать параметр наличия
  блока с фильтром по цене. если блок отсутствует, что маловероятно, SQL запрос
  будет выполнятся быстрее.

- опции для блока:
  - отключить определение максимальных границ цены (true по-умолчанию, чтобы пока
    не заморачиватся с реализацией дополнительного запроса)
  - отображать дополнительный интерфейс с группами (false, на будущее разбивка
    цены по кликабельным группам, т.е. |12|2|834|33| в срезе количества товаров)
  - дополнительная кнопка для подтверждения ввода (0 по-умолчанию)
    - (0) не отображается
    - (1) отображается обычной + отменяет подтверждение потерей фокуса
    - (2) отображается всплывающей + отменяет подтверждение потерей фокуса
  - основной интерфейс:
    - (0) два текстовых поля с разделителем (по-умолчанию)
    - (1) слайдер с двумя ползунками (определение границ включено)
    - (2) кликабельные группы цен (определение границ включено,
          без среза по кол-ву товаров)

- шаблон блока:
  - аналогичная структура, как у остальных
  - svg изображение для разделителя [-] текстовых полей

#### фронтэнд
- аналогичная структура блока (JS/CSS)
- блок уровня 2: он блокирует остальные блоки напрямую зависящие от
  общего количества записей в результате (пагинатор), а также
  фильтр по категориям, так как оба влияют на выборку (на одном уровне)
- тип интерфейса определяется при создании блока:
  - (0) текстовое поле [min], разделитель [-], текстовое поле [max]
  - ...
- блок растягивается на всю доступную ширину по-умолчанию. высота задается
  стандартной переменной --height, также как и у других горизонтальных
  блоков, для того чтобы можно было уменьшать неско блоков в строке
  пропорционально (потом).
- состояние блока locked: контролы заблокированы для ввода,
  значения сброшены и не отбражаются.
- при разблокировке установить значения и класс.
- при инициализации установить параметр необходимости доп.выборки
  минимального-максимального и среза по количеству товаров.
- при вводе (0):
  - при фокусе выделяется текущее значение в контроле (либо стандартное min/max).
  - можно вводить только целые, положительные числа.
  - завершением ввода считать нажатие Enter или потерб фокуса контролом.
  - при завершении ввода переключается стиль контрола - "значение установлено".
  - полным завершением ввода считать нажатие Enter или потерю фокуса обоими контроламию.
  - при полном завершении, значения переставляются если min>max, распространяются
    на все остальные блоки с фильтром по цене и инициируется перезагрузка каталога.
  - колесико мышки, а также стрелки вверх/вниз (прокручивают) значения
    в текущем контроле от min до max

#### дополнение (вложенная секция)
- необходимо дополнить блок опцией наличия секции. секция может содержать заголовок,
  например "Цена" и возможность скрывать/раскрывать содержимое. содержимым секции,
  если данная опция задана, является интерфейс фильтра.
- для того чтобы не повторять код для последующих блоков нужно адаптировать
  текущий код вложенных секций из фильтра категорий. создать отдельный объект
  MainSection во фронтенде и процедуру-генератор разметки в бэкэнде. подробно:
  - выделить стили из фильтра категорий в отдельный блок `.sm-blocks main-section`
  - выделить код из фильтра категорий в отдельный объект `MainSection`
  - выделить код из генератора разметки в отдельную процедуру `renderSection`
- отложить рефакторинг фильтра категорий
  


## 2020-08-24/30
#### изменения в алгоритме загрузчика (1)=>(2)=>(3), было (1)=>(3)

(1) парсинг скриптов/стилей браузером, запрос конфигурации и запрос
    содержимого корзины (объеденить в один запрос для сокращения общего времени загрузки).
    блоки в это вермя отображаются как заглушки, либо не отображаются/скрыты.
    почему? потому что некоторые блоки (пагинатор, список товаров) отображаются
    некорректно/криво без предварительного вычисления их размеров зависящих от
    различных настроек (напр. число элементов в таблице, кол-во кноп в пагинаторе)
    можно сделать их скрытыми, а можно отображать красивую или не очень заглушку,
    ранее было скрыто до полной загрузки (3).

(2) (a) создание блоков и определение их размеров (если требуется)
    (b) отображаем блоки частично, они неактивны т.е. пользователь не может
        взаимодействовать с ними.
    (c) ожидаем загрузку конфигурации и выполняем инициализацию блоков (один раз),
        инициализация заключается в подготовке данных (например, для блока сортировки
        нужно составить список возможных вариантов сортировки из конфигурации)
    (d) запуск первоначальной загрузки данных в каталог

(3) загрузка в каталог завершена, обновляем и активируем деактивированные блоки.
    ожидание действий пользователя.

(4) действие совершено - блокировка/деактивация блоков (только тех которые нужно)
    и выполнение нового запроса на сервер с обновленными данными.

(5) переход к (3).


#### HTML/CSS (реструктуризация шаблонов и стилей)

- ввести общий класс для всех блоков чтобы не повторять одни и те же стили
  для всех элементов управления внутри блока, а также какие-то общие состояния

- общие классы состояний для соостветствия стадиям (1)=>(2)=>(3) загрузчика:
  (1) div   > div   (пустышка/скрыт, неактивен)
  (2) div.v > div   (неактивен)
  (3) div.v > div.v (активен)

- единая начальная структура блоков: div > div и пустышка-placeholder рядом
```
  <div class="sm-blocks {{названиеБлока}} {{дополнительныйКласс}}">
    <div>{{содержимое}}</div>
    <svg>{{пустышкаЗаглушка}}</svg>
  </div>
```


#### JS (примерные переделки внутри скрипта)

- пройтись по обработчикам событий внутри каждого блока:
    init: оставить только подготовку данных (один раз)(2), остальное убрать,
          ранее также вешались события, считались размеры и обновлялся блок
  change: произошло изменеие (пользователь что-то выбрал)(нет изменений)
    lock: блокировка (нет изменений)
  unlock: разблокировка - удалить, объеденить с load
    load: данные загружены, нужно разблокировать и обновить блок

- все конструкторы блоков должны вешать события сразу

- конструкторы блоков (пагинатор, каталог) должны вызывать фунуции для 
  определения размеров сразу после создания блока (в конце конструктора).

- основной блок (каталог/список товаров):
  - объеденить запрос конфигурации и запрос содержимого корзины
  - ...

- блок фильтра категорий:
  - ...


