[![npm](http://nagarajanchinnasamy.com/subtotal/images/npm.svg)](https://www.npmjs.com/package/pivottable) [![cdnjs](http://nagarajanchinnasamy.com/subtotal/images/cdnjs.svg)](https://cdnjs.com/libraries/pivottable) [![tests](http://nagarajanchinnasamy.com/subtotal/images/tests.svg)](http://nagarajanchinnasamy.com/subtotal/tests/) [![license](http://nagarajanchinnasamy.com/subtotal/images/license.svg)](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/blob/master/LICENSE)


# Subtotal.js

Subtotal.js is an open-source JavaScript plugin for [PivotTable.js](https://github.com/nicolaskruchten/pivottable). Its originally written by [Nagarajan Chinnasamy](https://nagarajanchinnasamy.com/) at [Mindtree](http://mindtree.com/).

[PivotTable.js](https://github.com/nicolaskruchten/pivottable) is a Javascript Pivot Table library with drag'n'drop functionality built on top of jQuery/jQueryUI and originally written in CoffeeScript by [Nicolas Kruchten](http://nicolas.kruchten.com) at [Datacratic](http://datacratic.com). 


## What does it do?

Subtotal.js renders subtotal of rows and columns of a pivot table and lets the users to expand and collpase the rows.

![image](http://nagarajanchinnasamy.com/subtotal/images/subtotal-renderer-pivotui.png)

You can see the live demo at [examples page](http://nagarajanchinnasamy.com/subtotal/examples/index.html).

## How do I load the code?

Subtotal.js implements the [Universal Module Definition (UMD)](https://github.com/umdjs/umd) pattern and so should be compatible with most approaches to script loading and dependency management: direct script loading i.e. from [CDNJS](https://cdnjs.com/libraries/pivottable) or with [RequireJS](http://requirejs.org/), [Browserify](http://browserify.org/) etc. For the latter options, you can grab it from [NPM](https://www.npmjs.com/package/pivottable) with `npm install pivottable` or via [Bower](http://bower.io/) with `bower install pivottable`. 

If you are loading the scripts directly (as in the [examples](http://nagarajanchinnasamy.com/subtotal)), you need to:

1. load the dependencies:
  1. jQuery in all cases
  2. jQueryUI for the interactive `pivotUI()` function (see below)
  3. D3.js, C3.js and/or Google Charts if you use [charting plugins](https://github.com/nicolaskruchten/pivottable/wiki/Optional-Extra-Renderers)
2. load the PivotTable.js files:
  1. `pivot.min.js`
3. load the Subtotal.js files:
  1. `subtotal.min.js`

(Please look at the source code of the [exmaples](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/blob/master/examples/subtotal_pivot.html/) 

## How do I use the code?


### `pivot()`


### `pivotUI()`

## Where is the documentation?

More extensive documentation can be found in the [wiki](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki):


## How can I build the code and run the tests?

To install the development dependencies, just run `npm install`, which will create a `node_modules` directory with the files required to run the [Gulp](http://gulpjs.com/) build system.

After modifying any of the `.coffee` files at the top of the repo, you can compile/minify the files into the `dist` directory by running `node_modules/gulp/bin/gulp.js`

Once that's done, you can point your browser to `tests/index.html` to run the [Jasmine](http://jasmine.github.io/) test suite. You can view the [current test results here](http://nicolas.kruchten.com/pivottable/tests).

The easiest way to modify the code and work with the examples is to leave a `node_modules/gulp/bin/gulp.js watch serve` command running, which will automatically compile the CoffeeScript files when they are modified and will also run a local web server you can connect to to run the tests and examples.

## How can I contribute?

Pull requests are welcome! Here are some [Contribution Guidelines](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/blob/master/CONTRIBUTING.md).

## I have a question, how can I get in touch?

Please first check the [Frequently Asked Questions](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Frequently-Asked-Questions) and if you can't find what you're looking for there, or in the [wiki](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki), then please [create a GitHub Issue](https://github.com/nagarajanchinnasamy/subtotal/issues/new). When creating an issue, please try to provide a replicable test case so that others can more easily help you.

## Copyright & Licence (MIT License)

Subtotal.js is © 2016 Nagarajan Chinnasamy, Mindtree, other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
