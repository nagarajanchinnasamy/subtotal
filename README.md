[![npm](http://nagarajanchinnasamy.com/subtotal/images/subtotal_npm.svg)](https://www.npmjs.com/package/subtotal) [![tests](http://nagarajanchinnasamy.com/subtotal/images/subtotal_tests.svg)](http://nagarajanchinnasamy.com/subtotal/tests/) [![license](http://nagarajanchinnasamy.com/subtotal/images/subtotal_license.svg)](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/blob/master/LICENSE)


# Subtotal.js

[Subtotal.js](http://nagarajanchinnasamy.com/subtotal) is an open-source JavaScript plugin for **PivotTable.js** . Subtotal.js renders rows and columns of a pivot table with subtotals and lets the user to expand or collapse rows and columns. Its originally written by [Nagarajan Chinnasamy](https://github.com/nagarajanchinnasamy/) at [Mindtree](http://mindtree.com/).


It is available under an MIT license from [NPM](https://www.npmjs.com/package/subtotal) and [Bower](http://bower.io/) under the name `subtotal`. On [packagist.org](https://packagist.org/), it is `nagarajanchinnasamy/subtotal`.


[PivotTable.js](http://nicolas.kruchten.com/pivottable) is a Javascript Pivot Table library with drag'n'drop functionality built on top of jQuery/jQueryUI and originally written in CoffeeScript by [Nicolas Kruchten](http://nicolas.kruchten.com) at [Datacratic](http://datacratic.com). 


## What does it do?

Subtotal.js renders rows and columns of a pivot table with subtotals and lets the user to expand or collapse rows and columns.

![image](http://nagarajanchinnasamy.com/subtotal/images/subtotal-renderer-pivotui.png)

## Where can I see the demo?

You can see the live demo at [examples page](http://nagarajanchinnasamy.com/subtotal/examples/index.html).

## How can I get started?

To know how to load and use this library, please refer to [Getting Started Wiki Page](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki/Getting-Started)

## API Documentation?

Please refer to [Wiki Pages](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/wiki)

## How can I build the code and run the tests?

To install the development dependencies, just run `npm install`, which will create a `node_modules` directory with the files required to run the [Gulp](http://gulpjs.com/) build system.

After modifying any of the `.coffee` files at the top of the repo, you can compile/minify the files into the `dist` directory by running `node_modules/gulp/bin/gulp.js`

Once that's done, you can point your browser to `tests/index.html` to run the [Jasmine](http://jasmine.github.io/) test suite. You can view the [current test results here](http://nagarajanchinnasamy.com/subtotal/tests).

The easiest way to modify the code and work with the examples is to leave a `node_modules/gulp/bin/gulp.js watch serve` command running, which will automatically compile the CoffeeScript files when they are modified and will also run a local web server you can connect to to run the tests and examples.

## How can I contribute?

Pull requests are welcome! Here are some [Contribution Guidelines](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/blob/master/CONTRIBUTING.md).

## I have a question, how can I get in touch?

Please first check the [issues](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/issues) that are already raised and if you can't find what you're looking for there, then please [create a GitHub Issue](https://github.com/nagarajanchinnasamy/pivottable-subtotal-renderer/issues/new). When creating an issue, please try to provide a replicable test case so that others can more easily help you.

## Copyright & Licence (MIT License)

Subtotal.js is © 2016 Nagarajan Chinnasamy, Mindtree, other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
