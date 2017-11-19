* [aggregator](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Pivottable.js-Parameters#aggregator)  
* [aggregators](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Pivottable.js-Parameters#aggregators)  
* [dataClass](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Pivottable.js-Parameters#dataclass)  
* [renderer](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Pivottable.js-Parameters#renderer)  
* [rendererName](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Pivottable.js-Parameters#renderername)  
* [renderers](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Pivottable.js-Parameters#renderers)  

### aggregator

When using `pivot()` API, to make use of the aggregators provided by this plugin, value of `aggregator` parameter must be set to `$.pivotUtilities.subtotal_aggregators[<*name of a subtotal aggregator*>]`. Aggregator name can be one of the following:

    "Count As Fraction Of Parent Row"
    "Count As Fraction Of Parent Column"
    "Sum As Fraction Of Parent Row"
    "Sum As Fraction Of Parent Column"

### aggregators

`$.pivotUtilities.subtotal_aggregators` is a dictionary of aggregators specific to this plugin. Value of `aggregators` parameter must be set to `$.pivotUtilities.subtotal_aggregators`.

### dataClass

When using `pivot()` or `pivotUI()` API, value of `dataClass` parameter must be set to `$.pivotUtilities.SubtotalPivotData`.

### renderer

When using `pivot()` API, value of `renderer` parameter must be set to `$.pivotUtilities.subtotal_renderers[<*name of a subtotal renderer*>]`. Renderer name can be one of the following:

    "Table With Subtotal"
    "Table With Subtotal Bar Chart"
    "Table With Subtotal Heatmap"
    "Table With Subtotal Row Heatmap"
    "Table With Subtotal Col Heatmap"

### renderers

When using `pivotUI()` API, value of `renderers` parameter must be set to `$.pivotUtilities.subtotal_renderers`.

### rendererName

When using `pivotUI()` API, `rendererName` can take one of the following values:

    "Table With Subtotal"
    "Table With Subtotal Bar Chart"
    "Table With Subtotal Heatmap"
    "Table With Subtotal Row Heatmap"
    "Table With Subtotal Col Heatmap"
