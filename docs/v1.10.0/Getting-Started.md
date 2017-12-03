[Subtotal.js](http://nagarajanchinnasamy.com/subtotal) is an open-source JavaScript plugin for **PivotTable.js** . Subtotal.js renders rows and columns of a pivot table with subtotals and lets the user to expand or collapse rows and columns. Its originally written by [Nagarajan Chinnasamy](https://github.com/nagarajanchinnasamy/) at [Mindtree](http://mindtree.com/).


It is available under an MIT license from [NPM](https://www.npmjs.com/package/subtotal), [Packagist](https://packagist.org/packages/nagarajanchinnasamy/subtotal) and [Bower](http://bower.io/) under the name `subtotal`.


[PivotTable.js](http://nicolas.kruchten.com/pivottable) is a Javascript Pivot Table library with drag'n'drop functionality built on top of jQuery/jQueryUI and originally written in CoffeeScript by [Nicolas Kruchten](http://nicolas.kruchten.com) at [Datacratic](http://datacratic.com). 


## What does it do?

Subtotal.js renders rows and columns of a pivot table with subtotals and lets the user to expand or collapse rows and columns.

![image](http://nagarajanchinnasamy.com/subtotal/images/subtotal-renderer-pivotui.png)

## Where can I see the demo?

You can see the live demo at [examples page](http://nagarajanchinnasamy.com/subtotal/examples/index.html).

## How do I load the code?

Subtotal.js implements the [Universal Module Definition (UMD)](https://github.com/umdjs/umd) pattern and so should be compatible with most approaches to script loading and dependency management: direct script loading with [RequireJS](http://requirejs.org/), [Browserify](http://browserify.org/) etc. For these options, you can grab it from [NPM](https://www.npmjs.com/package/subtotal) with `npm install subtotal` or via [Bower](http://bower.io/) with `bower install subtotal`. 

If you are loading the scripts directly (as in the [examples](http://nagarajanchinnasamy.com/subtotal)), you need to:

1. load the dependencies:
    1. jQuery in all cases
    2. jQueryUI for the interactive `pivotUI()` function (see below)
    3. D3.js, C3.js and/or Google Charts if you use [charting plugins](https://github.com/nicolaskruchten/pivottable/wiki/Optional-Extra-Renderers)
2. load the PivotTable.js files:
    1. `pivot.min.js`
3. load the Subtotal.js files:
    1. `subtotal.min.js`

Here is the source code of an [exmaple](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/blob/master/examples/105_default.html/) 

## How do I use the code?

You can use Subtotal.js with either `pivot()` or `pivotUI()` method of PivotTable.js.

### To use `pivot()` method

1. Set the value of `dataClass` parameter to `$.pivotUtilities.SubtotalPivotData` 
2. Set the value of `renderer` parameter to `$.pivotUtilities.subtotal_renderers[<*rendererName*>]`
3. Optionally, set `rendererOptions`

```javascript
$(function(){
    $.getJSON("mps.json", function(mps) {
        $("#output").pivot(mps, {
            dataClass: $.pivotUtilities.SubtotalPivotData,
            rows: ["Gender", "Province"],
            cols: ["Party", "Age"],
            renderer: $.pivotUtilities.subtotal_renderers["Table With Subtotal"],
            rendererOptions: {
                // rowSubtotalDisplay: {
                    // displayOnTop: true,
                    // disableExpandCollapse: true,
                    // hideOnExpand: true,
                    // collapseAt: 0,
                    // disableFrom: 1 
                // },
                // colSubtotalDisplay: {
                    // hideOnExpand: true,
                    // collapseAt: 0,
                    // disableFrom: 1,
                    // disableExpandCollapse: true
                // }
            }
        });
    });
});
```

### To use `pivotUI()` method

1. Set the value of `dataClass` parameter to `$.pivotUtilities.SubtotalPivotData` 
2. Set the value of `renderers` parameter to `$.pivotUtilities.subtotal_renderers`
3. Set the value of `rendererName` parameter to one of the subtotal renderers name
4. Optionally, set `rendererOptions`

```javascript
$(function(){
    $.getJSON("mps.json", function(mps) {
        $("#output").pivotUI(mps, {
            dataClass: $.pivotUtilities.SubtotalPivotData,
            rows: ["Gender", "Province"],
            cols: ["Party", "Age"],
            renderers: $.pivotUtilities.subtotal_renderers,
            rendererName: "Table With Subtotal",
            rendererOptions: {
                // rowSubtotalDisplay: {
                    // displayOnTop: true,
                    // disableExpandCollapse: true,
                    // hideOnExpand: true,
                    // collapseAt: 0,
                    // disableFrom: 1 
                // },
                // colSubtotalDisplay: {
                    // hideOnExpand: true,
                    // collapseAt: 0,
                    // disableFrom: 1,
                    // disableExpandCollapse: true
                // }
            }
        });
    });
});
```

