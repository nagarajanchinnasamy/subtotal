(function() {
  var callWithJQuery,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  callWithJQuery = function(pivotModule) {
    if (typeof exports === "object" && typeof module === "object") {
      return pivotModule(require("jquery"));
    } else if (typeof define === "function" && define.amd) {
      return define(["jquery"], pivotModule);
    } else {
      return pivotModule(jQuery);
    }
  };

  callWithJQuery(function($) {
    var SubtotalPivotData, SubtotalRenderer;
    SubtotalPivotData = (function(superClass) {
      var processKey;

      extend(SubtotalPivotData, superClass);

      function SubtotalPivotData(input, opts) {
        SubtotalPivotData.__super__.constructor.call(this, input, opts);
      }

      processKey = function(record, totals, keys, attrs, f) {
        var addKey, attr, flatKey, k, key, len, ref;
        key = [];
        addKey = false;
        for (k = 0, len = attrs.length; k < len; k++) {
          attr = attrs[k];
          key.push((ref = record[attr]) != null ? ref : "null");
          flatKey = key.join(String.fromCharCode(0));
          if (!totals[flatKey]) {
            totals[flatKey] = f(key.slice());
            addKey = true;
          }
          totals[flatKey].push(record);
        }
        if (addKey) {
          keys.push(key);
        }
        return key;
      };

      SubtotalPivotData.prototype.processRecord = function(record) {
        var colKey, fColKey, fRowKey, flatColKey, flatRowKey, i, j, k, m, n, ref, results, rowKey;
        rowKey = [];
        colKey = [];
        this.allTotal.push(record);
        rowKey = processKey(record, this.rowTotals, this.rowKeys, this.rowAttrs, (function(_this) {
          return function(key) {
            return _this.aggregator(_this, key, []);
          };
        })(this));
        colKey = processKey(record, this.colTotals, this.colKeys, this.colAttrs, (function(_this) {
          return function(key) {
            return _this.aggregator(_this, [], key);
          };
        })(this));
        m = rowKey.length - 1;
        n = colKey.length - 1;
        if (m < 0 || n < 0) {
          return;
        }
        results = [];
        for (i = k = 0, ref = m; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
          fRowKey = rowKey.slice(0, i + 1);
          flatRowKey = fRowKey.join(String.fromCharCode(0));
          if (!this.tree[flatRowKey]) {
            this.tree[flatRowKey] = {};
          }
          results.push((function() {
            var l, ref1, results1;
            results1 = [];
            for (j = l = 0, ref1 = n; 0 <= ref1 ? l <= ref1 : l >= ref1; j = 0 <= ref1 ? ++l : --l) {
              fColKey = colKey.slice(0, j + 1);
              flatColKey = fColKey.join(String.fromCharCode(0));
              if (!this.tree[flatRowKey][flatColKey]) {
                this.tree[flatRowKey][flatColKey] = this.aggregator(this, fRowKey, fColKey);
              }
              results1.push(this.tree[flatRowKey][flatColKey].push(record));
            }
            return results1;
          }).call(this));
        }
        return results;
      };

      return SubtotalPivotData;

    })($.pivotUtilities.PivotData);
    $.pivotUtilities.SubtotalPivotData = SubtotalPivotData;
    SubtotalRenderer = function(pivotData, opts) {
      var allTotal, buildColHeaderHeaders, buildColHeaders, buildColTotals, buildColTotalsHeader, buildGrandTotal, buildRowHeaderHeaders, buildRowHeaders, buildRowTotalsHeader, buildValues, colAttrs, colKeys, colTotals, collapseRow, collapseRowsAt, createCell, defaults, expandRow, main, minus, plus, processKeys, rowAttrs, rowKeys, rowTotals, toggleRow, tree;
      defaults = {
        localeStrings: {
          totals: "Totals"
        }
      };
      opts = $.extend(defaults, opts);
      plus = "\u25B6";
      minus = "\u25E2";
      colAttrs = pivotData.colAttrs;
      rowAttrs = pivotData.rowAttrs;
      rowKeys = pivotData.getRowKeys();
      colKeys = pivotData.getColKeys();
      tree = pivotData.tree;
      rowTotals = pivotData.rowTotals;
      colTotals = pivotData.colTotals;
      allTotal = pivotData.allTotal;
      createCell = function(cellType, className, textContent, attributes) {
        var attr, th, val;
        th = document.createElement(cellType);
        if (className) {
          th.className = className;
        }
        if (textContent !== null && textContent !== void 0) {
          th.textContent = textContent;
        }
        if (attributes) {
          for (attr in attributes) {
            if (!hasProp.call(attributes, attr)) continue;
            val = attributes[attr];
            th.setAttribute(attr, val);
          }
        }
        return th;
      };
      processKeys = function(keysArr, className) {
        var c, flatKey, header, headers, lastCol, lastRow, node, nodePos, r, rMark, repeats, th, x;
        lastRow = keysArr.length - 1;
        lastCol = keysArr[0].length - 1;
        rMark = [];
        headers = [];
        th = createCell("th", className, keysArr[0][0]);
        flatKey = keysArr[0][0];
        nodePos = 0;
        node = {
          "node": nodePos,
          "row": 0,
          "col": 0,
          "th": th,
          "parent": null,
          "children": [],
          "descendants": lastCol,
          "leaves": 1,
          "flatKey": flatKey
        };
        headers[0] = node;
        rMark[0] = node;
        c = 1;
        while (c <= lastCol) {
          th = createCell("th", className, keysArr[0][c]);
          flatKey = flatKey + String.fromCharCode(0) + keysArr[0][c];
          ++nodePos;
          node = {
            "node": nodePos,
            "row": 0,
            "col": c,
            "th": th,
            "parent": rMark[c - 1],
            "children": [],
            "descendants": lastCol - c,
            "leaves": 1,
            "flatKey": flatKey
          };
          rMark[c] = node;
          rMark[c - 1].children.push(node);
          ++c;
        }
        rMark[lastCol].leaves = 0;
        r = 1;
        while (r <= lastRow) {
          repeats = true;
          flatKey = "";
          c = 0;
          while (c <= lastCol) {
            flatKey = c === 0 ? keysArr[r][c] : flatKey + String.fromCharCode(0) + keysArr[r][c];
            if ((keysArr[r][c] === keysArr[rMark[c].row][c]) && (c !== lastCol) && repeats) {
              repeats = true;
              ++c;
              continue;
            }
            th = createCell("th", className, keysArr[r][c]);
            ++nodePos;
            header = {
              "node": nodePos,
              "row": r,
              "col": c,
              "th": th,
              "parent": null,
              "children": [],
              "descendants": 0,
              "leaves": 1,
              "flatKey": flatKey
            };
            if (c === 0) {
              headers.push(header);
            } else {
              header.parent = rMark[c - 1];
              rMark[c - 1].children.push(header);
              x = 0;
              while (x <= c - 1) {
                rMark[x].descendants = rMark[x].descendants + 1;
                ++x;
              }
            }
            rMark[c] = header;
            repeats = false;
            ++c;
          }
          c = 0;
          while (c <= lastCol) {
            rMark[c].leaves = rMark[c].leaves + 1;
            ++c;
          }
          rMark[lastCol].leaves = 0;
          ++r;
        }
        return headers;
      };
      buildColHeaderHeaders = function(thead, colHeaderRowsArr, rowAttrs) {
        var c, k, ref, results, th, tr;
        tr = document.createElement("tr");
        if (rowAttrs.length !== 0) {
          tr.appendChild(createCell("th", null, null, {
            "colspan": rowAttrs.length,
            "rowspan": colAttrs.length
          }));
        }
        tr.appendChild(createCell("th", "pvtAxisLabel", colAttrs[0]));
        colHeaderRowsArr[0] = tr;
        thead.appendChild(tr);
        results = [];
        for (c = k = 1, ref = colAttrs.length; 1 <= ref ? k <= ref : k >= ref; c = 1 <= ref ? ++k : --k) {
          if (!(c < colAttrs.length)) {
            continue;
          }
          tr = document.createElement("tr");
          th = createCell("th", "pvtAxisLabel", colAttrs[c]);
          tr.appendChild(th);
          colHeaderRowsArr[c] = tr;
          thead.appendChild(tr);
          results.push(++c);
        }
        return results;
      };
      buildColHeaders = function(colHeaderRowsArr, colHeaderColsArr, colHeader, parent, colAttrs, rowAttrs) {
        var h, k, len, ref, rowspan, th, tr;
        ref = colHeader.children;
        for (k = 0, len = ref.length; k < len; k++) {
          h = ref[k];
          buildColHeaders(colHeaderRowsArr, colHeaderColsArr, h, colHeader, colAttrs, rowAttrs);
        }
        tr = colHeaderRowsArr[colHeader.col];
        th = colHeader.th;
        if (colHeader.col === colAttrs.length - 1 && rowAttrs.length !== 0) {
          th.setAttribute("rowspan", 2);
        }
        if (colHeader.children.length !== 0) {
          th.setAttribute("colspan", colHeader.descendants);
        }
        tr.appendChild(th);
        if (colHeader.children.length !== 0) {
          rowspan = colAttrs.length - colHeader.col + (rowAttrs.length !== 0 ? 1 : 0);
          th = createCell("th", "pvtColLabel", '', {
            "rowspan": rowspan
          });
          tr.appendChild(th);
        }
        colHeader.tr = tr;
        return colHeaderColsArr.push(colHeader);
      };
      buildRowHeaderHeaders = function(thead, rowHeaderHeaders, rowAttrs, colAttrs) {
        var k, len, rowAttr, th, tr;
        tr = document.createElement("tr");
        for (k = 0, len = rowAttrs.length; k < len; k++) {
          rowAttr = rowAttrs[k];
          th = createCell("th", "pvtAxisLabel", rowAttr);
          tr.appendChild(th);
        }
        if (colAttrs.length !== 0) {
          th = createCell("th");
          tr.appendChild(th);
        }
        thead.appendChild(tr);
        return rowHeaderHeaders.tr = tr;
      };
      buildRowTotalsHeader = function(tr, colAttrs, rowAttrs) {
        var rowspan, th;
        rowspan = 1;
        if (colAttrs.length !== 0) {
          rowspan = colAttrs.length + (rowAttrs.length === 0 ? 0 : 1);
        }
        th = createCell("th", "pvtTotalLabel", opts.localeStrings.totals, {
          "rowspan": rowspan
        });
        return tr.appendChild(th);
      };
      buildRowHeaders = function(tbody, rowHeaderRowsArr, rowHeader, rowAttrs, colAttrs) {
        var colspan, h, k, len, ref, results, th, tr;
        tr = document.createElement("tr");
        th = rowHeader.th;
        th.setAttribute("rowspan", rowHeader.descendants + 1);
        if (rowHeader.col === rowAttrs.length - 1 && colAttrs.length !== 0) {
          th.setAttribute("colspan", 2);
        }
        th.setAttribute("data-node", rowHeaderRowsArr.length);
        tr.appendChild(th);
        if (rowHeader.children.length !== 0) {
          th.onclick = function(event) {
            event = event || window.event;
            return toggleRow(rowHeaderRowsArr, parseInt(event.target.getAttribute("data-node")));
          };
          colspan = rowAttrs.length - (rowHeader.col + 1) + (colAttrs.length !== 0 ? 1 : 0);
          th = createCell("th", "pvtRowLabel", '', {
            "colspan": colspan
          });
          tr.appendChild(th);
        }
        rowHeader.clickStatus = "expanded";
        rowHeader.th.textContent = " " + minus + " " + rowHeader.th.textContent;
        rowHeader.tr = tr;
        rowHeaderRowsArr.push(rowHeader);
        tbody.appendChild(tr);
        ref = rowHeader.children;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          h = ref[k];
          results.push(buildRowHeaders(tbody, rowHeaderRowsArr, h, rowAttrs, colAttrs));
        }
        return results;
      };
      buildValues = function(rowHeaderRowsArr, colHeaderColsArr) {
        var aggregator, colHeader, flatColKey, flatRowKey, k, l, len, len1, ref, results, rowHeader, style, td, totalAggregator, tr, val;
        results = [];
        for (k = 0, len = rowHeaderRowsArr.length; k < len; k++) {
          rowHeader = rowHeaderRowsArr[k];
          tr = rowHeader.tr;
          flatRowKey = rowHeader.flatKey;
          for (l = 0, len1 = colHeaderColsArr.length; l < len1; l++) {
            colHeader = colHeaderColsArr[l];
            flatColKey = colHeader.flatKey;
            aggregator = (ref = tree[flatRowKey][flatColKey]) != null ? ref : {
              value: (function() {
                return null;
              }),
              format: function() {
                return "";
              }
            };
            val = aggregator.value();
            style = "pvtVal";
            style = colHeader.children.length !== 0 ? style + " pvtSubtotal" : style;
            style = style + " row" + rowHeader.row + " col" + colHeader.col;
            td = createCell("td", style, aggregator.format(val), {
              "data-value": val
            });
            tr.appendChild(td);
          }
          totalAggregator = rowTotals[flatRowKey];
          val = totalAggregator.value();
          td = createCell("td", "pvtTotal rowTotal", totalAggregator.format(val), {
            "data-value": val,
            "data-row": "row" + rowHeader.row,
            "data-col": "col" + rowHeader.col
          });
          results.push(tr.appendChild(td));
        }
        return results;
      };
      buildColTotalsHeader = function(rowAttrs, colAttrs) {
        var colspan, th, tr;
        tr = document.createElement("tr");
        colspan = rowAttrs.length + (colAttrs.length === 0 ? 0 : 1);
        th = createCell("th", "pvtTotalLabel", opts.localeStrings.totals, {
          "colspan": colspan
        });
        tr.appendChild(th);
        return tr;
      };
      buildColTotals = function(tr, colHeaderColsArr) {
        var h, k, len, results, td, totalAggregator, val;
        results = [];
        for (k = 0, len = colHeaderColsArr.length; k < len; k++) {
          h = colHeaderColsArr[k];
          totalAggregator = colTotals[h.flatKey];
          val = totalAggregator.value();
          td = createCell("td", "pvtTotal colTotal", totalAggregator.format(val), {
            "data-value": val,
            "data-for": "col" + h.col
          });
          results.push(tr.appendChild(td));
        }
        return results;
      };
      buildGrandTotal = function(result, tr) {
        var td, totalAggregator, val;
        totalAggregator = allTotal;
        val = totalAggregator.value();
        td = createCell("td", "pvtGrandTotal", totalAggregator.format(val), {
          "data-value": val
        });
        tr.appendChild(td);
        return result.appendChild(tr);
      };
      collapseRow = function(rowHeaderRows, r) {
        var d, h, i, k, p, ref, rowspan, str;
        if (!rowHeaderRows[r]) {
          return;
        }
        h = rowHeaderRows[r];
        rowspan = 0;
        for (i = k = 1, ref = h.descendants; 1 <= ref ? k <= ref : k >= ref; i = 1 <= ref ? ++k : --k) {
          if (!(h.descendants !== 0)) {
            continue;
          }
          d = rowHeaderRows[r + i];
          if (d.descendants !== 0) {
            str = d.th.textContent;
            d.th.textContent = str.substr(0, 1) + plus + str.substr(1 + minus.length);
          }
          d.clickStatus = "collapsed";
          d.th.setAttribute("rowspan", 1);
          if (d.tr.style.display !== "none") {
            ++rowspan;
            d.tr.style.display = "none";
          }
        }
        p = h.parent;
        while (p !== null) {
          p.th.setAttribute("rowspan", parseInt(p.th.getAttribute("rowspan")) - rowspan);
          p = p.parent;
        }
        if (h.descendants !== 0) {
          str = h.th.textContent;
          h.th.textContent = str.substr(0, 1) + plus + str.substr(1 + plus.length);
        }
        h.clickStatus = "collapsed";
        h.th.setAttribute("rowspan", 1);
        return h.tr.style.display = "";
      };
      expandRow = function(rowHeaderRows, r) {
        var c, d, h, i, k, l, len, p, ref, ref1, results, rowspan, str;
        if (!rowHeaderRows[r]) {
          return;
        }
        rowspan = 0;
        h = rowHeaderRows[r];
        for (i = k = 1, ref = h.descendants; 1 <= ref ? k <= ref : k >= ref; i = 1 <= ref ? ++k : --k) {
          if (!(h.descendants !== 0)) {
            continue;
          }
          d = rowHeaderRows[r + i];
          if (d.descendants !== 0) {
            str = d.th.textContent;
            d.th.textContent = str.substr(0, 1) + plus + str.substr(1 + minus.length);
          }
          d.clickStatus = "collapsed";
          d.th.setAttribute("rowspan", 1);
          if (d.tr.style.display !== "none") {
            --rowspan;
            d.tr.style.display = "none";
          }
        }
        ref1 = h.children;
        for (l = 0, len = ref1.length; l < len; l++) {
          c = ref1[l];
          if (c.tr.style.display === "none") {
            ++rowspan;
            c.tr.style.display = "";
          }
        }
        h.th.setAttribute("rowspan", h.children.length + 1);
        if (h.descendants !== 0) {
          str = h.th.textContent;
          h.th.textContent = str.substr(0, 1) + minus + str.substr(1 + minus.length);
        }
        h.clickStatus = "expanded";
        h.tr.style.display = "";
        p = h.parent;
        results = [];
        while (p !== null) {
          p.th.setAttribute("rowspan", rowspan + parseInt(p.th.getAttribute("rowspan")));
          results.push(p = p.parent);
        }
        return results;
      };
      toggleRow = function(rowHeaderRows, r) {
        if (!rowHeaderRows[r]) {
          return;
        }
        if (rowHeaderRows[r].clickStatus === "collapsed") {
          return expandRow(rowHeaderRows, r);
        } else {
          return collapseRow(rowHeaderRows, r);
        }
      };
      collapseRowsAt = function(rowHeaderRows, col) {
        var h, i, nRows, results;
        i = 0;
        nRows = rowHeaderRows.length;
        results = [];
        while (i < nRows) {
          h = rowHeaderRows[i];
          if (h.col === col) {
            collapseRow(rowHeaderRows, h.node);
            results.push(i = i + h.descendants + 1);
          } else {
            results.push(++i);
          }
        }
        return results;
      };
      main = function(rowAttrs, rowKeys, colAttrs, colKeys) {
        var colHeaderCols, colHeaderRows, colHeaders, h, idx, k, l, len, len1, result, rowHeaderHeaders, rowHeaderRows, rowHeaders, sTime, tbody, thead, tr;
        rowHeaders = [];
        colHeaders = [];
        rowHeaderHeaders = {};
        rowHeaderRows = [];
        colHeaderRows = [];
        colHeaderCols = [];
        if (rowAttrs.length !== 0) {
          rowHeaders = processKeys(rowKeys, "pvtRowLabel");
        }
        if (colAttrs.length !== 0) {
          sTime = Date.now();
          colHeaders = processKeys(colKeys, "pvtColLabel");
        }
        result = document.createElement("table");
        result.className = "pvtTable";
        thead = document.createElement("thead");
        result.appendChild(thead);
        if (colAttrs.length !== 0) {
          buildColHeaderHeaders(thead, colHeaderRows, rowAttrs);
          for (k = 0, len = colHeaders.length; k < len; k++) {
            h = colHeaders[k];
            buildColHeaders(colHeaderRows, colHeaderCols, h, null, colAttrs, rowAttrs);
          }
        }
        if (rowAttrs.length !== 0) {
          buildRowHeaderHeaders(thead, rowHeaderHeaders, rowAttrs, colAttrs);
          if (colAttrs.length === 0) {
            buildRowTotalsHeader(rowHeaderHeaders.tr, colAttrs, rowAttrs);
          }
        }
        if (colAttrs.length !== 0) {
          sTime = Date.now();
          buildRowTotalsHeader(colHeaderRows[0], colAttrs, rowAttrs);
        }
        tbody = document.createElement("tbody");
        result.appendChild(tbody);
        if (rowAttrs.length !== 0) {
          for (l = 0, len1 = rowHeaders.length; l < len1; l++) {
            h = rowHeaders[l];
            buildRowHeaders(tbody, rowHeaderRows, h, rowAttrs, colAttrs);
          }
        }
        buildValues(rowHeaderRows, colHeaderCols);
        tr = buildColTotalsHeader(rowAttrs, colAttrs);
        if (colAttrs.length !== 0) {
          buildColTotals(tr, colHeaderCols);
        }
        buildGrandTotal(tbody, tr);
        result.setAttribute("data-numrows", rowKeys.length);
        result.setAttribute("data-numcols", colKeys.length);
        idx = rowAttrs.indexOf(opts.collapseRowsAt);
        if (idx !== -1 && idx !== rowAttrs.length - 1) {
          collapseRowsAt(rowHeaderRows, idx);
        }
        return result;
      };
      return main(rowAttrs, rowKeys, colAttrs, colKeys);
    };
    return $.pivotUtilities.subtotal_renderers = {
      "Table With Subtotal": function(pvtData, opts) {
        return SubtotalRenderer(pvtData, opts);
      },
      "Table With Subtotal Bar Chart": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).barchart();
      },
      "Table With Subtotal Heatmap": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).heatmap();
      },
      "Table With Subtotal Row Heatmap": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).heatmap("rowheatmap");
      },
      "Table With Subtotal Col Heatmap": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).heatmap("colheatmap");
      }
    };
  });

}).call(this);

//# sourceMappingURL=subtotal.js.map
