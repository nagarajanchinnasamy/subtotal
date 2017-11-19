* [arrowCollapsed](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#arrowcollapsed)
* [arrowExpanded](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#arrowexpanded)
* [collapseColsAt](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#collapsecolsat)
* [collapseRowsAt](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#collapserowsat)
* [colSubtotalDisplay](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#colsubtotaldisplay)
* [rowSubtotalDisplay](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#rowsubtotaldisplay)
* [table.eventHandlers](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Subtotal.js-Renderer-Options#tableeventhandlers)

### arrowCollapsed

This option can be used to customize the default collapsed arrow ("\u25B6") displayed with subtotal row/column labels and pivot axis labels.

### arrowExpanded

This option can be used to customize the default expanded arrow ("\u25B6") displayed with subtotal row/column labels and pivot axis labels.

### collapseColsAt

This option can be set to a `numeric` value as index of one of the elements of `cols` array. If this option is set, columns are collapsed at the given column attribute whenever the pivot table is (re)rendered. The default behavior is to render all columns expanded initially (ie., no collapse).

### collapseRowsAt

This option can be set to a `numeric` value as index of one of the elements of `rows` array. If this option is set, rows are collapsed at the given row attribute whenever the pivot table is (re)rendered.  The default behavior is to render all rows expanded initially (ie., no collapse).


### colSubtotalDisplay

Is a dictionary of options that can be used to control the way column-subtotals are displayed. It supports following options:

    "disableExpandCollapse" - Disables expand collapse operations.
    "disableSubtotal" - Disables displaying of subtotals. This also disables expand collapse operations.
    "hideOnExpand" - Enables hiding of subtotals when expanded.

### rowSubtotalDisplay

Is a dictionary of options that can be used to control the way row-subtotals are displayed. It supports following options:

    "disableExpandCollapse" - Disables expand collapse operations.
    "disableSubtotal" - Disables displaying of subtotals. This also disables expand collapse operations.
    "hideOnExpand" - Enables hiding of subtotals when expanded.

### table.eventHandlers

This option is set to a dictionary of events and their callback functions. On the occurrence of an event given in this option, the corresponding callback function is invoked by passing the table cell element, value of the element, filtering criteria to fetch matching records from data and `SubtotalPivotData` instance. See [this example](http://nagarajanchinnasamy.com/subtotal/examples/260_event_handlers.html).
