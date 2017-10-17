(function() {
  var callWithJQuery,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

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
    var SubtotalPivotData, SubtotalRenderer, aggregatorTemplates, subtotalAggregatorTemplates, usFmtPct;
    SubtotalPivotData = (function(superClass) {
      var processKey;

      extend(SubtotalPivotData, superClass);

      function SubtotalPivotData(input, opts) {
        SubtotalPivotData.__super__.constructor.call(this, input, opts);
      }

      processKey = function(record, totals, keys, attrs, getAggregator) {
        var addKey, attr, flatKey, k, key, len, ref;
        key = [];
        addKey = false;
        for (k = 0, len = attrs.length; k < len; k++) {
          attr = attrs[k];
          key.push((ref = record[attr]) != null ? ref : "null");
          flatKey = key.join(String.fromCharCode(0));
          if (!totals[flatKey]) {
            totals[flatKey] = getAggregator(key.slice());
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
      var addClass, allTotal, arrowCollapsed, arrowExpanded, buildColHeader, buildColHeaderHeader, buildColHeaderHeaders, buildColHeaderHeadersClickEvents, buildColTotals, buildColTotalsHeader, buildGrandTotal, buildRowHeader, buildRowHeaderHeaders, buildRowHeaderHeadersClickEvents, buildRowTotalsHeader, buildValues, classColCollapsed, classColExpanded, classColHide, classColShow, classCollapsed, classExpanded, classRowCollapsed, classRowExpanded, classRowHide, classRowShow, clickStatusCollapsed, clickStatusExpanded, colAttrs, colDisableAfter, colDisableFrom, colKeys, colTotals, collapseAt, collapseChildCol, collapseCol, collapseRow, collapseShowColSubtotal, collapseShowRowSubtotal, colsCollapseAt, createElement, defaults, expandAt, expandChildCol, expandChildRow, expandCol, expandHideColSubtotal, expandHideRowSubtotal, expandRow, expandShowColSubtotal, expandShowRowSubtotal, getTableEventHandlers, hasClass, hideDescendantCol, hideDescendantRow, isColDisable, isColDisableExpandCollapse, isColHideOnExpand, isDisplayOnRight, isDisplayOnTop, isRowDisable, isRowDisableExpandCollapse, isRowHideOnExpand, main, processKeys, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, removeClass, replaceClass, rowAttrs, rowDisableAfter, rowDisableFrom, rowKeys, rowTotals, rowsCollapseAt, setAttributes, setColInitParams, setRowInitParams, showChildCol, showChildRow, tree;
      defaults = {
        table: {
          clickCallback: null
        },
        localeStrings: {
          totals: "Totals"
        }
      };
      opts = $.extend(true, {}, defaults, opts);
      isRowDisable = (ref = opts.rowSubtotalDisplay) != null ? ref.disableSubtotal : void 0;
      rowDisableAfter = typeof ((ref1 = opts.rowSubtotalDisplay) != null ? ref1.disableAfter : void 0) !== 'undefined' ? opts.rowSubtotalDisplay.disableAfter : 9999;
      if (typeof (typeof opts.rowSubtotalDisplay === "function" ? opts.rowSubtotalDisplay(disableFrom === 'undefined') : void 0)) {
        rowDisableFrom = isRowDisable ? 0 : rowDisableAfter + 1;
      } else {
        rowDisableFrom = opts.rowSubtotalDisplay.disableFrom;
      }
      isRowHideOnExpand = (ref2 = opts.rowSubtotalDisplay) != null ? ref2.hideOnExpand : void 0;
      isRowDisableExpandCollapse = (ref3 = opts.rowSubtotalDisplay) != null ? ref3.disableExpandCollapse : void 0;
      isDisplayOnTop = typeof ((ref4 = opts.rowSubtotalDisplay) != null ? ref4.displayOnTop : void 0) !== 'undefined' ? opts.rowSubtotalDisplay.displayOnTop : true;
      isColDisable = (ref5 = opts.colSubtotalDisplay) != null ? ref5.disableSubtotal : void 0;
      isColHideOnExpand = (ref6 = opts.colSubtotalDisplay) != null ? ref6.hideOnExpand : void 0;
      isColDisableExpandCollapse = (ref7 = opts.colSubtotalDisplay) != null ? ref7.disableExpandCollapse : void 0;
      colDisableAfter = typeof ((ref8 = opts.colSubtotalDisplay) != null ? ref8.disableAfter : void 0) !== 'undefined' ? opts.colSubtotalDisplay.disableAfter : 9999;
      if (typeof (typeof opts.colSubtotalDisplay === "function" ? opts.colSubtotalDisplay(disableFrom === 'undefined') : void 0)) {
        colDisableFrom = isColDisable ? 0 : colDisableAfter + 1;
      } else {
        colDisableFrom = opts.colSubtotalDisplay.disableFrom;
      }
      isDisplayOnRight = typeof ((ref9 = opts.colSubtotalDisplay) != null ? ref9.displayOnRight : void 0) !== 'undefined' ? opts.rowSubtotalDisplay.displayOnRight : true;
      arrowCollapsed = opts.arrowCollapsed != null ? opts.arrowCollapsed : opts.arrowCollapsed = "\u25B6";
      arrowExpanded = opts.arrowExpanded != null ? opts.arrowExpanded : opts.arrowExpanded = "\u25E2";
      colsCollapseAt = typeof opts.collapseColsAt !== 'undefined' ? opts.collapseColsAt : 9999;
      rowsCollapseAt = typeof opts.collapseRowsAt !== 'undefined' ? opts.collapseRowsAt : 9999;
      colAttrs = pivotData.colAttrs;
      rowAttrs = pivotData.rowAttrs;
      rowKeys = pivotData.getRowKeys();
      colKeys = pivotData.getColKeys();
      tree = pivotData.tree;
      rowTotals = pivotData.rowTotals;
      colTotals = pivotData.colTotals;
      allTotal = pivotData.allTotal;
      classRowExpanded = "rowexpanded";
      classRowCollapsed = "rowcollapsed";
      classRowHide = "rowhide";
      classRowShow = "rowshow";
      classColExpanded = "colexpanded";
      classColCollapsed = "colcollapsed";
      classColHide = "colhide";
      classColShow = "colshow";
      clickStatusExpanded = "expanded";
      clickStatusCollapsed = "collapsed";
      classExpanded = "expanded";
      classCollapsed = "collapsed";
      isDisplayOnTop = false;
      hasClass = function(element, className) {
        var regExp;
        regExp = new RegExp("(?:^|\\s)" + className + "(?!\\S)", "g");
        return element.className.match(regExp) !== null;
      };
      removeClass = function(element, className) {
        var k, len, name, ref10, regExp, results;
        ref10 = className.split(" ");
        results = [];
        for (k = 0, len = ref10.length; k < len; k++) {
          name = ref10[k];
          regExp = new RegExp("(?:^|\\s)" + name + "(?!\\S)", "g");
          results.push(element.className = element.className.replace(regExp, ''));
        }
        return results;
      };
      addClass = function(element, className) {
        var k, len, name, ref10, results;
        ref10 = className.split(" ");
        results = [];
        for (k = 0, len = ref10.length; k < len; k++) {
          name = ref10[k];
          if (!hasClass(element, name)) {
            results.push(element.className += " " + name);
          } else {
            results.push(void 0);
          }
        }
        return results;
      };
      replaceClass = function(element, replaceClassName, byClassName) {
        removeClass(element, replaceClassName);
        return addClass(element, byClassName);
      };
      getTableEventHandlers = function(value, rowValues, colValues) {
        var attr, event, eventHandlers, filters, handler, i, ref10;
        if (!opts.table && !opts.table.eventHandlers) {
          return;
        }
        eventHandlers = {};
        ref10 = opts.table.eventHandlers;
        for (event in ref10) {
          if (!hasProp.call(ref10, event)) continue;
          handler = ref10[event];
          filters = {};
          for (i in colAttrs) {
            if (!hasProp.call(colAttrs, i)) continue;
            attr = colAttrs[i];
            if (colValues[i] != null) {
              filters[attr] = colValues[i];
            }
          }
          for (i in rowAttrs) {
            if (!hasProp.call(rowAttrs, i)) continue;
            attr = rowAttrs[i];
            if (rowValues[i] != null) {
              filters[attr] = rowValues[i];
            }
          }
          eventHandlers[event] = function(e) {
            return handler(e, value, filters, pivotData);
          };
        }
        return eventHandlers;
      };
      createElement = function(elementType, className, textContent, attributes, eventHandlers) {
        var attr, e, event, handler, val;
        e = document.createElement(elementType);
        if (className != null) {
          e.className = className;
        }
        if (textContent != null) {
          e.textContent = textContent;
        }
        if (attributes != null) {
          for (attr in attributes) {
            if (!hasProp.call(attributes, attr)) continue;
            val = attributes[attr];
            e.setAttribute(attr, val);
          }
        }
        if (eventHandlers != null) {
          for (event in eventHandlers) {
            if (!hasProp.call(eventHandlers, event)) continue;
            handler = eventHandlers[event];
            e.addEventListener(event, handler);
          }
        }
        return e;
      };
      setAttributes = function(e, attrs) {
        var a, results, v;
        results = [];
        for (a in attrs) {
          if (!hasProp.call(attrs, a)) continue;
          v = attrs[a];
          results.push(e.setAttribute(a, v));
        }
        return results;
      };
      processKeys = function(keysArr, className) {
        var lastIdx, row;
        lastIdx = keysArr[0].length - 1;
        tree = {
          children: []
        };
        row = 0;
        keysArr.reduce((function(_this) {
          return function(val0, k0) {
            var col;
            col = 0;
            k0.reduce(function(acc, curVal, curIdx, arr) {
              var i, k, key, node, ref10;
              if (!acc[curVal]) {
                key = k0.slice(0, col + 1);
                acc[curVal] = {
                  row: row,
                  col: col,
                  descendants: 0,
                  children: [],
                  text: curVal,
                  key: key,
                  flatKey: key.join(String.fromCharCode(0)),
                  firstLeaf: null,
                  leaves: 0,
                  parent: col !== 0 ? acc : null,
                  th: createElement("th", className, curVal),
                  childrenSpan: 0
                };
                acc.children.push(curVal);
              }
              if (col > 0) {
                acc.descendants++;
              }
              col++;
              if (curIdx === lastIdx) {
                node = tree;
                for (i = k = 0, ref10 = lastIdx - 1; 0 <= ref10 ? k <= ref10 : k >= ref10; i = 0 <= ref10 ? ++k : --k) {
                  if (!(lastIdx > 0)) {
                    continue;
                  }
                  node[k0[i]].leaves++;
                  if (!node[k0[i]].firstLeaf) {
                    node[k0[i]].firstLeaf = acc[curVal];
                  }
                  node = node[k0[i]];
                }
                return tree;
              }
              return acc[curVal];
            }, tree);
            row++;
            return tree;
          };
        })(this), tree);
        return tree;
      };
      setColInitParams = function(col) {
        var init;
        init = {
          colArrow: arrowExpanded,
          colClass: classColExpanded,
          colClickStatus: clickStatusExpanded
        };
        if (col >= colsCollapseAt) {
          init = {
            colArrow: arrowCollapsed,
            colClass: classColCollapsed,
            colClickStatus: clickStatusCollapsed
          };
        }
        if (col >= colDisableFrom) {
          init = {
            colArrow: ""
          };
        }
        return init;
      };
      buildColHeaderHeader = function(thead, colHeaderHeaders, rowAttrs, colAttrs, tr, col) {
        var className, colAttr, init, textContent, th;
        colAttr = colAttrs[col];
        textContent = colAttr;
        className = "pvtAxisLabel";
        init = setColInitParams(col);
        if (col < colAttrs.length - 1) {
          className += " " + init.colClass;
          if (!(isColDisableExpandCollapse || isColDisable || col > colDisableAfter)) {
            textContent = " " + init.colArrow + " " + colAttr;
          }
        }
        th = createElement("th", className, textContent);
        th.setAttribute("data-colAttr", colAttr);
        tr.appendChild(th);
        colHeaderHeaders.push({
          tr: tr,
          th: th,
          clickStatus: init.colClickStatus,
          expandedCount: 0,
          nodes: []
        });
        return thead.appendChild(tr);
      };
      buildColHeaderHeaders = function(thead, colHeaderHeaders, rowAttrs, colAttrs) {
        var c, k, ref10, results, tr;
        tr = createElement("tr");
        if (rowAttrs.length !== 0) {
          tr.appendChild(createElement("th", null, null, {
            colspan: rowAttrs.length,
            rowspan: colAttrs.length
          }));
        }
        buildColHeaderHeader(thead, colHeaderHeaders, rowAttrs, colAttrs, tr, 0);
        results = [];
        for (c = k = 1, ref10 = colAttrs.length; 1 <= ref10 ? k <= ref10 : k >= ref10; c = 1 <= ref10 ? ++k : --k) {
          if (!(c < colAttrs.length)) {
            continue;
          }
          tr = createElement("tr");
          results.push(buildColHeaderHeader(thead, colHeaderHeaders, rowAttrs, colAttrs, tr, c));
        }
        return results;
      };
      buildColHeaderHeadersClickEvents = function(colHeaderHeaders, colHeaderCols, colAttrs) {
        var colAttr, i, k, n, ref10, results, th;
        n = colAttrs.length - 1;
        results = [];
        for (i = k = 0, ref10 = n; 0 <= ref10 ? k <= ref10 : k >= ref10; i = 0 <= ref10 ? ++k : --k) {
          if (!(i < n)) {
            continue;
          }
          th = colHeaderHeaders[i].th;
          colAttr = colAttrs[i];
          results.push(th.onclick = function(event) {
            event = event || window.event;
            return toggleColHeaderHeader(colHeaderHeaders, colHeaderCols, colAttrs, event.target.getAttribute("data-colAttr"));
          });
        }
        return results;
      };
      buildColHeader = function(colHeaderHeaders, colHeaderCols, h, rowAttrs, colAttrs, node) {
        var chKey, firstChild, hh, init, k, len, ref10, ref11;
        ref10 = h.children;
        for (k = 0, len = ref10.length; k < len; k++) {
          chKey = ref10[k];
          buildColHeader(colHeaderHeaders, colHeaderCols, h[chKey], rowAttrs, colAttrs, node);
        }
        hh = colHeaderHeaders[h.col];
        if (h.col < colsCollapseAt) {
          ++hh.expandedCount;
        }
        hh.nodes.push(h);
        h.node = node.counter;
        init = setColInitParams(h.col);
        if (h.children.length !== 0) {
          firstChild = h[h.children[0]];
        }
        addClass(h.th, classColShow + " col" + h.row + " colcol" + h.col + " " + init.colClass);
        h.th.setAttribute("data-colnode", h.node);
        if (h.children.length !== 0) {
          h.th.colSpan = h.childrenSpan;
        }
        if (h.children.length === 0 && rowAttrs.length !== 0) {
          h.th.rowSpan = 2;
        }
        if (h.leaves > 1 && !(isColDisable || h.col >= colDisableFrom)) {
          if (!isColDisableExpandCollapse) {
            h.th.textContent = init.colArrow + " " + h.text;
            h.th.onclick = function(event) {
              event = event || window.event;
              return toggleCol(colHeaderHeaders, colHeaderCols, parseInt(event.target.getAttribute("data-colnode")));
            };
            h.sTh = createElement("th", "pvtColLabelFiller pvtColSubtotal");
            h.sTh.setAttribute("data-colnode", h.node);
            h.sTh.rowSpan = colAttrs.length - h.col;
            if ((isColHideOnExpand && h.col < colsCollapseAt) || h.col > colsCollapseAt) {
              h.sTh.style.display = "none";
            }
            firstChild.tr.appendChild(h.sTh);
            h.th.colSpan++;
          }
        }
        if ((ref11 = h.parent) != null) {
          ref11.childrenSpan += h.th.colSpan;
        }
        h.clickStatus = init.colClickStatus;
        hh.tr.appendChild(h.th);
        h.tr = hh.tr;
        colHeaderCols.push(h);
        return node.counter++;
      };
      setRowInitParams = function(col) {
        var init;
        init = {
          rowArrow: arrowExpanded,
          rowClass: classRowExpanded,
          rowClickStatus: clickStatusExpanded
        };
        if (col >= rowsCollapseAt) {
          init = {
            rowArrow: arrowCollapsed,
            rowClass: classRowCollapsed,
            rowClickStatus: clickStatusCollapsed
          };
        }
        if (col >= rowDisableFrom) {
          init = {
            rowArrow: ""
          };
        }
        return init;
      };
      buildRowHeaderHeaders = function(thead, rowHeaderHeaders, rowAttrs, colAttrs) {
        var className, i, rowAttr, textContent, th, tr;
        tr = createElement("tr");
        rowHeaderHeaders.hh = [];
        for (i in rowAttrs) {
          if (!hasProp.call(rowAttrs, i)) continue;
          rowAttr = rowAttrs[i];
          textContent = rowAttr;
          className = "pvtAxisLabel";
          if (i < rowAttrs.length - 1) {
            className += " expanded";
            if (!(isRowDisableExpandCollapse || i >= rowDisableFrom || i >= rowsCollapseAt)) {
              textContent = " " + arrowExpanded + " " + rowAttr;
            }
          }
          th = createElement("th", className, textContent);
          th.setAttribute("data-rowAttr", rowAttr);
          tr.appendChild(th);
          rowHeaderHeaders.hh.push({
            th: th,
            clickStatus: i < rowsCollapseAt ? clickStatusExpanded : clickStatusCollapsed,
            expandedCount: 0,
            headers: []
          });
        }
        if (colAttrs.length !== 0) {
          th = createElement("th");
          tr.appendChild(th);
        }
        thead.appendChild(tr);
        return rowHeaderHeaders.tr = tr;
      };
      buildRowHeaderHeadersClickEvents = function(rowHeaderHeaders, rowHeaderRows, rowAttrs) {
        var i, k, n, ref10, results, rowAttr, th;
        n = rowAttrs.length - 1;
        results = [];
        for (i = k = 0, ref10 = n; 0 <= ref10 ? k <= ref10 : k >= ref10; i = 0 <= ref10 ? ++k : --k) {
          if (!(i < n)) {
            continue;
          }
          th = rowHeaderHeaders.hh[i];
          rowAttr = rowAttrs[i];
          results.push(th.th.onclick = function(event) {
            event = event || window.event;
            return toggleRowHeaderHeader(rowHeaderHeaders, rowHeaderRows, rowAttrs, event.target.getAttribute("data-rowAttr"));
          });
        }
        return results;
      };
      buildRowTotalsHeader = function(tr, rowAttrs, colAttrs) {
        var rowspan, th;
        rowspan = 1;
        if (colAttrs.length !== 0) {
          rowspan = colAttrs.length + (rowAttrs.length === 0 ? 0 : 1);
        }
        th = createElement("th", "pvtTotalLabel rowTotal", opts.localeStrings.totals, {
          rowspan: rowspan
        });
        return tr.appendChild(th);
      };
      buildRowHeader = function(tbody, rowHeaderHeaders, rowHeaderRows, h, rowAttrs, colAttrs, node) {
        var chKey, firstChild, hh, init, k, len, ref10, ref11;
        ref10 = h.children;
        for (k = 0, len = ref10.length; k < len; k++) {
          chKey = ref10[k];
          buildRowHeader(tbody, rowHeaderHeaders, rowHeaderRows, h[chKey], rowAttrs, colAttrs, node);
        }
        hh = rowHeaderHeaders.hh[h.col];
        if (h.col < rowsCollapseAt) {
          ++hh.expandedCount;
        }
        hh.headers.push(h);
        h.node = node.counter;
        init = setRowInitParams(h.col);
        if (h.children.length !== 0) {
          firstChild = h[h.children[0]];
        }
        addClass(h.th, "row" + h.row + " rowcol" + h.col + " " + classRowShow);
        if (h.th.children.length !== 0) {
          addClass(h.th, "pvtRowSubtotal");
        }
        h.th.setAttribute("data-rownode", h.node);
        if (h.col === rowAttrs.length - 1 && colAttrs.length !== 0) {
          h.th.colSpan = 2;
        }
        if (h.children.length !== 0) {
          h.th.rowSpan = h.childrenSpan;
        }
        if ((isDisplayOnTop && h.children.length === 1) || (!isDisplayOnTop && h.children.length !== 0)) {
          h.tr = firstChild.tr;
          h.tr.insertBefore(h.th, firstChild.th);
          h.sTh = firstChild.sTh;
        } else {
          h.tr = createElement("tr", "pvtRowSubtotal row" + h.row);
          h.tr.appendChild(h.th);
        }
        if (h.leaves > 1 && !(isRowDisable || h.col >= rowDisableFrom)) {
          if (!isRowDisableExpandCollapse) {
            addClass(h.th, init.rowClass);
            h.th.textContent = init.rowArrow + " " + h.text;
            h.th.onclick = function(event) {
              event = event || window.event;
              return toggleRow(rowHeaderHeaders, rowHeaderRows, parseInt(event.target.getAttribute("data-rownode")));
            };
          }
          if (h.children.length > 1) {
            h.sTh = createElement("th", "pvtRowLabelFiller pvtRowSubtotal row" + h.row + " rowcol" + h.col + " " + init.rowClass);
            h.sTh.setAttribute("data-rownode", h.node);
            h.sTh.colSpan = rowAttrs.length - (h.col + 1) + (colAttrs.length !== 0 ? 1 : 0);
            if ((isRowHideOnExpand && h.col < rowsCollapseAt) || h.col > rowsCollapseAt) {
              h.sTh.style.display = "none";
            }
            h.th.rowSpan++;
            addClass(h.tr, init.rowClass);
            if (isDisplayOnTop) {
              h.tr.appendChild(h.sTh);
            } else {
              h.sTr = createElement("tr", "pvtRowSubtotal row" + h.row + " " + init.rowClass);
              h.sTr.appendChild(h.sTh);
              tbody.appendChild(h.sTr);
            }
          }
          tbody.insertBefore(h.tr, firstChild.tr);
        } else {
          if (h.children.length === 0) {
            tbody.appendChild(h.tr);
          }
        }
        if ((ref11 = h.parent) != null) {
          ref11.childrenSpan += h.th.rowSpan;
        }
        h.clickStatus = init.rowClickStatus;
        rowHeaderRows.push(h);
        return node.counter++;
      };
      buildValues = function(tbody, rowHeaderRows, colHeaderCols) {
        var aggregator, colHeader, colInit, eventHandlers, flatColKey, flatRowKey, isColSubtotal, isRowSubtotal, k, l, len, len1, ref10, results, rowHeader, rowInit, style, td, totalAggregator, val;
        results = [];
        for (k = 0, len = rowHeaderRows.length; k < len; k++) {
          rowHeader = rowHeaderRows[k];
          rowInit = setRowInitParams(rowHeader.col);
          flatRowKey = rowHeader.flatKey;
          isRowSubtotal = rowHeader.descendants !== 0;
          for (l = 0, len1 = colHeaderCols.length; l < len1; l++) {
            colHeader = colHeaderCols[l];
            flatColKey = colHeader.flatKey;
            aggregator = (ref10 = tree[flatRowKey][flatColKey]) != null ? ref10 : {
              value: (function() {
                return null;
              }),
              format: function() {
                return "";
              }
            };
            val = aggregator.value();
            isColSubtotal = colHeader.descendants !== 0;
            colInit = setColInitParams(colHeader.col);
            style = "pvtVal";
            if (isColSubtotal) {
              style += " pvtColSubtotal " + colInit.colClass;
            }
            if (isRowSubtotal) {
              style += " pvtRowSubtotal " + rowInit.rowClass;
            }
            style += (isRowSubtotal && (rowHeader.col >= rowDisableFrom || (isRowHideOnExpand && rowHeader.col < rowsCollapseAt))) || (rowHeader.col > rowsCollapseAt) ? " " + classRowHide : " " + classRowShow;
            style += (isColSubtotal && (isColDisable || colHeader.col > colDisableAfter || (isColHideOnExpand && colHeader.col < colsCollapseAt))) || (colHeader.col > colsCollapseAt) ? " " + classColHide : " " + classColShow;
            style += (" row" + rowHeader.row) + (" col" + colHeader.row) + (" rowcol" + rowHeader.col) + (" colcol" + colHeader.col);
            eventHandlers = getTableEventHandlers(val, rowHeader.key, colHeader.key);
            td = createElement("td", style, aggregator.format(val), {
              "data-value": val,
              "data-rownode": rowHeader.node,
              "data-colnode": colHeader.node
            }, eventHandlers);
            if (!isDisplayOnTop) {
              if ((rowHeader.col > rowsCollapseAt || colHeader.col > colsCollapseAt) || (isRowSubtotal && (rowHeader.col >= rowDisableFrom || (isRowHideOnExpand && rowHeader.col < rowsCollapseAt))) || (isColSubtotal && (isColDisable || colHeader.col > colDisableAfter || (isColHideOnExpand && colHeader.col < colsCollapseAt)))) {
                td.style.display = "none";
              }
            }
            rowHeader.tr.appendChild(td);
          }
          totalAggregator = rowTotals[flatRowKey];
          val = totalAggregator.value();
          style = "pvtTotal rowTotal " + rowInit.rowClass;
          if (isRowSubtotal) {
            style += " pvtRowSubtotal ";
          }
          style += isRowSubtotal && (rowHeader.col >= rowDisableFrom || !isDisplayOnTop || (isRowHideOnExpand && rowHeader.col < rowsCollapseAt)) ? " " + classRowHide : " " + classRowShow;
          style += " row" + rowHeader.row + " rowcol" + rowHeader.col;
          td = createElement("td", style, totalAggregator.format(val), {
            "data-value": val,
            "data-row": "row" + rowHeader.row,
            "data-rowcol": "col" + rowHeader.col,
            "data-rownode": rowHeader.node
          }, getTableEventHandlers(val, rowHeader.key, []));
          if (!isDisplayOnTop) {
            if ((rowHeader.col > rowsCollapseAt) || (isRowSubtotal && (rowHeader.col >= rowDisableFrom || (isRowHideOnExpand && rowHeader.col < rowsCollapseAt)))) {
              td.style.display = "none";
            }
          }
          results.push(rowHeader.tr.appendChild(td));
        }
        return results;
      };
      buildColTotalsHeader = function(rowAttrs, colAttrs) {
        var colspan, th, tr;
        tr = createElement("tr");
        colspan = rowAttrs.length + (colAttrs.length === 0 ? 0 : 1);
        th = createElement("th", "pvtTotalLabel colTotal", opts.localeStrings.totals, {
          colspan: colspan
        });
        tr.appendChild(th);
        return tr;
      };
      buildColTotals = function(tr, colHeaderCols) {
        var clsNames, colInit, h, k, len, results, td, totalAggregator, val;
        results = [];
        for (k = 0, len = colHeaderCols.length; k < len; k++) {
          h = colHeaderCols[k];
          if (!(h.leaves !== 1)) {
            continue;
          }
          colInit = setColInitParams(h.col);
          clsNames = "pvtVal pvtTotal colTotal " + colInit.colClass + " col" + h.row + " colcol" + h.col;
          if (h.children.length !== 0) {
            clsNames += " pvtColSubtotal";
          }
          totalAggregator = colTotals[h.flatKey];
          val = totalAggregator.value();
          td = createElement("td", clsNames, totalAggregator.format(val), {
            "data-value": val,
            "data-for": "col" + h.col,
            "data-colnode": "" + h.node
          }, getTableEventHandlers(val, [], h.key));
          if ((h.col > colsCollapseAt) || (h.children.length !== 0 && (isColDisable || h.col > colDisableAfter || (isColHideOnExpand && h.col < colsCollapseAt)))) {
            td.style.display = "none";
          }
          results.push(tr.appendChild(td));
        }
        return results;
      };
      buildGrandTotal = function(result, tr) {
        var td, totalAggregator, val;
        totalAggregator = allTotal;
        val = totalAggregator.value();
        td = createElement("td", "pvtGrandTotal", totalAggregator.format(val), {
          "data-value": val
        }, getTableEventHandlers(val, [], []));
        tr.appendChild(td);
        return result.appendChild(tr);
      };
      hideDescendantCol = function(d) {
        return $(d.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + d.node + "\"], th[data-colnode=\"" + d.node + "\"]").removeClass(classColShow).addClass(classColHide).css('display', "none");
      };
      collapseShowColSubtotal = function(h) {
        $(h.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + h.node + "\"], th[data-colnode=\"" + h.node + "\"]").removeClass(classColExpanded + " " + classColHide).addClass(classColCollapsed + " " + classColShow).not(".pvtRowSubtotal." + classRowHide).css('display', "");
        h.th.textContent = " " + arrowCollapsed + " " + h.text;
        return h.th.colSpan = 1;
      };
      collapseChildCol = function(ch, h) {
        var chKey, k, len, ref10;
        ref10 = ch.children;
        for (k = 0, len = ref10.length; k < len; k++) {
          chKey = ref10[k];
          collapseChildCol(ch[chKey], h);
        }
        return hideDescendantCol(ch);
      };
      collapseCol = function(colHeaderHeaders, colHeaderCols, c, opts) {
        var ch, chKey, colHeaderHeader, colSpan, h, i, k, l, len, p, ref10, ref11, ref12, results;
        if (isColDisable || isColDisableExpandCollapse || !colHeaderCols[c]) {
          return;
        }
        h = colHeaderCols[c];
        if (h.col >= colDisableFrom || h.clickStatus === clickStatusCollapsed) {
          return;
        }
        colSpan = h.th.colSpan - 1;
        ref10 = h.children;
        for (k = 0, len = ref10.length; k < len; k++) {
          chKey = ref10[k];
          ch = h[chKey];
          collapseChildCol(ch, h);
        }
        collapseShowColSubtotal(h);
        p = h.parent;
        while (p !== null) {
          p.th.colSpan -= colSpan;
          p = p.parent;
        }
        h.clickStatus = clickStatusCollapsed;
        colHeaderHeader = colHeaderHeaders[h.col];
        colHeaderHeader.expandedCount--;
        if (colHeaderHeader.expandedCount === 0) {
          results = [];
          for (i = l = ref11 = h.col, ref12 = colHeaderHeaders.length - 2; ref11 <= ref12 ? l <= ref12 : l >= ref12; i = ref11 <= ref12 ? ++l : --l) {
            if (!(i <= colDisableAfter)) {
              continue;
            }
            colHeaderHeader = colHeaderHeaders[i];
            replaceClass(colHeaderHeader.th, classExpanded, classCollapsed);
            colHeaderHeader.th.textContent = " " + arrowCollapsed + " " + colHeaderHeader.th.getAttribute("data-colAttr");
            results.push(colHeaderHeader.clickStatus = clickStatusCollapsed);
          }
          return results;
        }
      };
      showChildCol = function(ch) {
        return $(ch.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + ch.node + "\"], th[data-colnode=\"" + ch.node + "\"]").removeClass(classColHide).addClass(classColShow).not(".pvtRowSubtotal." + classRowHide).css('display', "");
      };
      expandHideColSubtotal = function(h) {
        $(h.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + h.node + "\"], th[data-colnode=\"" + h.node + "\"]").removeClass(classColCollapsed + " " + classColShow).addClass(classColExpanded + " " + classColHide).css('display', "none");
        return h.th.style.display = "";
      };
      expandShowColSubtotal = function(h) {
        $(h.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + h.node + "\"], th[data-colnode=\"" + h.node + "\"]").removeClass(classColCollapsed + " " + classColHide).addClass(classColExpanded + " " + classColShow).not(".pvtRowSubtotal." + classRowHide).css('display', "");
        h.th.style.display = "";
        ++h.th.colSpan;
        if (h.sTh != null) {
          return h.sTh.style.display = "";
        }
      };
      expandChildCol = function(ch) {
        var chKey, k, len, ref10, results;
        if (ch.descendants !== 0 && hasClass(ch.th, classColExpanded) && (isColDisable || ch.col > colDisableAfter || isColHideOnExpand)) {
          ch.th.style.display = "";
        } else {
          showChildCol(ch);
        }
        if (ch.clickStatus !== clickStatusCollapsed) {
          ref10 = ch.children;
          results = [];
          for (k = 0, len = ref10.length; k < len; k++) {
            chKey = ref10[k];
            results.push(expandChildCol(ch[chKey]));
          }
          return results;
        }
      };
      expandCol = function(colHeaderHeaders, colHeaderCols, c, opts) {
        var ch, chKey, colSpan, h, hh, k, len, p, ref10;
        if (isColDisable || isColDisableExpandCollapse || !colHeaderCols[c]) {
          return;
        }
        h = colHeaderCols[c];
        if (h.col >= colDisableFrom || h.clickStatus === clickStatusExpanded) {
          return;
        }
        colSpan = 0;
        ref10 = h.children;
        for (k = 0, len = ref10.length; k < len; k++) {
          chKey = ref10[k];
          ch = h[chKey];
          expandChildCol(ch);
          colSpan += ch.th.colSpan;
        }
        h.th.colSpan = colSpan;
        if (h.children.length !== 0) {
          replaceClass(h.th, classColCollapsed, classColExpanded);
          h.th.textContent = " " + arrowExpanded + " " + h.text;
          if (isColHideOnExpand) {
            expandHideColSubtotal(h);
            --colspan;
          } else {
            expandShowColSubtotal(h);
          }
        }
        p = h.parent;
        while (p) {
          p.th.colSpan += colSpan;
          p = p.parent;
        }
        h.clickStatus = clickStatusExpanded;
        hh = colHeaderHeaders[h.col];
        ++hh.expandedCount;
        if (hh.expandedCount === hh.headers.length) {
          replaceClass(hh.th, classCollapsed, classExpanded);
          hh.th.textContent = " " + arrowExpanded + " " + hh.th.getAttribute("data-colAttr");
          hh.clickStatus = clickStatusExpanded;
        }
        return console.warn(h.text + ": " + colHeaderCols[38].th.colSpan);
      };
      hideDescendantRow = function(d) {
        var cell, cells, k, l, len, len1;
        if (isDisplayOnTop) {
          d.tr.style.display = "none";
        }
        cells = d.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          replaceClass(cell, classRowShow, classRowHide);
        }
        if (!isDisplayOnTop) {
          for (l = 0, len1 = cells.length; l < len1; l++) {
            cell = cells[l];
            cell.style.display = "none";
          }
          if (d.sTh) {
            d.sTh.style.display = "none";
          }
          return d.th.style.display = "none";
        }
      };
      collapseShowRowSubtotal = function(h) {
        var cell, cells, k, len;
        cells = h.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          removeClass(cell, classRowExpanded + " " + classRowHide);
          addClass(cell, classRowCollapsed + " " + classRowShow);
          if (!hasClass(cell, classColHide)) {
            cell.style.display = "";
          }
        }
        h.sTh.textContent = " " + arrowCollapsed + " " + h.sTh.getAttribute("data-rowHeader");
        replaceClass(h.sTh, classRowExpanded, classRowCollapsed);
        replaceClass(h.tr, classRowExpanded, classRowCollapsed);
        return h.tr.style.display = "";
      };
      collapseRow = function(rowHeaderHeaders, rowHeaderRows, r, opts) {
        var d, h, hh, i, isRowSubtotal, j, k, l, p, ref10, ref11, ref12, results, rowSpan;
        h = rowHeaderRows[r];
        if (!h || h.clickStatus === clickStatusCollapsed || h.col >= rowDisableFrom || isRowDisableExpandCollapse) {
          return;
        }
        rowSpan = h.th.rowSpan;
        isRowSubtotal = h.descendants !== 0;
        for (i = k = 1, ref10 = h.descendants; 1 <= ref10 ? k <= ref10 : k >= ref10; i = 1 <= ref10 ? ++k : --k) {
          if (!(h.descendants !== 0)) {
            continue;
          }
          d = rowHeaderRows[r - i];
          hideDescendantRow(d);
        }
        if (!isDisplayOnTop) {
          h.th.style.display = "none";
        }
        if (isRowSubtotal) {
          collapseShowRowSubtotal(h);
        }
        if (isDisplayOnTop) {
          p = h.parent;
          while (p) {
            p.th.rowSpan -= rowSpan;
            p = p.parent;
          }
        }
        h.clickStatus = clickStatusCollapsed;
        hh = rowHeaderHeaders.hh[h.col];
        hh.expandedCount--;
        if (hh.expandedCount !== 0) {
          return;
        }
        results = [];
        for (j = l = ref11 = h.col, ref12 = rowHeaderHeaders.hh.length - 2; ref11 <= ref12 ? l <= ref12 : l >= ref12; j = ref11 <= ref12 ? ++l : --l) {
          if (!(j < rowDisableFrom)) {
            continue;
          }
          hh = rowHeaderHeaders.hh[j];
          replaceClass(hh.th, classExpanded, classCollapsed);
          hh.th.textContent = " " + arrowCollapsed + " " + hh.th.getAttribute("data-rowAttr");
          results.push(hh.clickStatus = clickStatusCollapsed);
        }
        return results;
      };
      showChildRow = function(h) {
        var cell, cells, k, l, len, len1;
        cells = h.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          replaceClass(cell, classRowHide, classRowShow);
        }
        if (!isDisplayOnTop) {
          for (l = 0, len1 = cells.length; l < len1; l++) {
            cell = cells[l];
            if (!hasClass(cell, classColHide)) {
              cell.style.display = "";
            }
          }
          if (h.descendants === 0 || h.clickStatus !== clickStatusCollapsed) {
            h.th.style.display = "";
          }
          if (h.sTh) {
            h.sTh.style.display = "";
          }
        }
        return h.tr.style.display = "";
      };
      expandShowRowSubtotal = function(h) {
        var cell, cells, k, len;
        cells = h.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          removeClass(cell, classRowCollapsed + " " + classRowHide);
          addClass(cell, classRowExpanded + " " + classRowShow);
          if (!hasClass(cell, classColHide)) {
            cell.style.display = "";
          }
        }
        h.sTh.textContent = " " + arrowExpanded + " " + h.sTh.getAttribute("data-rowHeader");
        h.sTh.style.display = "";
        replaceClass(h.sTh, classRowCollapsed, classRowExpanded);
        h.th.style.display = "";
        replaceClass(h.th, classRowCollapsed, classRowExpanded);
        replaceClass(h.tr, classRowCollapsed, classRowExpanded);
        return h.tr.style.display = "";
      };
      expandHideRowSubtotal = function(h) {
        var cell, cells, k, len;
        cells = h.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          removeClass(cell, classRowCollapsed + " " + classRowShow);
          addClass(cell, classRowExpanded + " " + classRowHide);
        }
        h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute("data-rowHeader");
        h.th.style.display = "";
        replaceClass(h.tr, classRowCollapsed, classRowExpanded);
        return h.tr.style.display = "none";
      };
      expandChildRow = function(ch) {
        var gch, k, len, nShown, ref10;
        nShown = 0;
        if (ch.descendants !== 0) {
          showChildRow(ch);
          nShown++;
          ref10 = ch.children;
          for (k = 0, len = ref10.length; k < len; k++) {
            gch = ref10[k];
            if (ch.clickStatus !== clickStatusCollapsed) {
              nShown += expandChildRow(gch);
            }
          }
        } else {
          showChildRow(ch);
          nShown++;
        }
        return nShown;
      };
      expandRow = function(rowHeaderHeaders, rowHeaderRows, r, opts) {
        var ch, h, hh, isRowSubtotal, k, len, nShown, p, ref10;
        h = rowHeaderRows[r];
        if (!h || h.clickStatus === clickStatusExpanded || isRowDisableExpandCollapse || h.col >= rowDisableFrom) {
          return;
        }
        isRowSubtotal = h.descendants !== 0;
        nShown = 0;
        ref10 = h.children;
        for (k = 0, len = ref10.length; k < len; k++) {
          ch = ref10[k];
          nShown += expandChildRow(ch, 0);
        }
        if (isRowSubtotal) {
          if (isRowHideOnExpand) {
            expandHideRowSubtotal(h);
          } else {
            expandShowRowSubtotal(h);
          }
        }
        if (isDisplayOnTop) {
          h.th.rowSpan = nShown;
          p = h.parent;
          while (p) {
            p.th.rowSpan += nShown;
            p = p.parent;
          }
        }
        h.clickStatus = clickStatusExpanded;
        hh = rowHeaderHeaders.hh[h.col];
        ++hh.expandedCount;
        if (hh.expandedCount === hh.headers.length) {
          replaceClass(hh.th, classCollapsed, classExpanded);
          hh.th.textContent = " " + arrowExpanded + " " + hh.th.getAttribute("data-rowAttr");
          return hh.clickStatus = clickStatusExpanded;
        }
      };
      collapseAt = function(headerHeaders, headers, attrs, attr, collapse, opts) {
        var h, hh, i, idx, k, n, ref10, ref11, results;
        if (opts.disableSubtotal || opts.disableExpandCollapse) {
          return;
        }
        idx = attr;
        if (typeof attr === 'string') {
          idx = attrs.indexOf(attr);
        }
        n = attrs.length - 2;
        if (idx < 0 || n < idx) {
          return;
        }
        results = [];
        for (i = k = ref10 = idx, ref11 = n; ref10 <= ref11 ? k <= ref11 : k >= ref11; i = ref10 <= ref11 ? ++k : --k) {
          if (!(i <= opts.disableFrom)) {
            continue;
          }
          hh = headerHeaders[i];
          replaceClass(hh.th, classExpanded, classCollapsed);
          hh.th.textContent = " " + arrowCollapsed + " " + attrs[i];
          hh.clickStatus = clickStatusCollapsed;
          results.push((function() {
            var l, len, ref12, results1;
            ref12 = hh.headers;
            results1 = [];
            for (l = 0, len = ref12.length; l < len; l++) {
              h = ref12[l];
              if (h.clickStatus !== clickStatusCollapsed && h.th.style.display !== "none" && h.leaves > 1) {
                results1.push(collapse(headerHeaders, headers, h.node, opts));
              }
            }
            return results1;
          })());
        }
        return results;
      };
      expandAt = function(headerHeaders, headerNodes, attrs, attr, expand, opts) {
        var h, hh, i, idx, k, l, len, ref10, ref11, results;
        if (opts.disableSubtotal || opts.disableExpandCollapse) {
          return;
        }
        idx = attr;
        if (typeof attr === 'string') {
          idx = attrs.indexOf(attr);
        }
        if (idx < 0 || idx === attrs.length - 1) {
          return;
        }
        for (i = k = 0, ref10 = idx; 0 <= ref10 ? k <= ref10 : k >= ref10; i = 0 <= ref10 ? ++k : --k) {
          if (!(i < opts.disableFrom)) {
            continue;
          }
          hh = headerHeaders[i];
          replaceClass(hh.th, classCollapsed, classExpanded);
          hh.th.textContent = " " + arrowExpanded + " " + attrs[i];
          hh.clickStatus = clickStatusExpanded;
          ref11 = hh.headers;
          for (l = 0, len = ref11.length; l < len; l++) {
            h = ref11[l];
            if (h.leaves > 1) {
              expand(headerHeaders, headerNodes, h.node);
            }
          }
        }
        ++idx;
        results = [];
        while (idx < attrs.length - 1 && idx < opts.disableFrom) {
          hh = headerHeaders[idx];
          if (hh.expandedCount === 0) {
            replaceClass(hh.th, classExpanded, classCollapsed);
            hh.th.textContent = " " + arrowCollapsed + " " + attrs[idx];
            hh.clickStatus = clickStatusCollapsed;
          } else if (hh.expandedCount === hh.nodes.length) {
            replaceClass(hh.th, classCollapsed, classExpanded);
            hh.th.textContent = " " + arrowExpanded + " " + attrs[idx];
            hh.clickStatus = clickStatusExpanded;
          }
          results.push(++idx);
        }
        return results;
      };
      main = function(rowAttrs, rowKeys, colAttrs, colKeys) {
        var chKey, colHeaderCols, colHeaderHeaders, colHeaders, k, l, len, len1, node, ref10, ref11, result, rowHeaderHeaders, rowHeaderRows, rowHeaders, tbody, thead, tr;
        rowHeaderHeaders = {};
        rowHeaderRows = [];
        colHeaderHeaders = [];
        colHeaderCols = [];
        if (rowAttrs.length > 0 && rowKeys.length > 0) {
          rowHeaders = processKeys(rowKeys, "pvtRowLabel");
        }
        if (colAttrs.length > 0 && colKeys.length > 0) {
          colHeaders = processKeys(colKeys, "pvtColLabel");
        }
        result = createElement("table", "pvtTable", null, {
          style: "display: none;"
        });
        thead = createElement("thead");
        result.appendChild(thead);
        if (colAttrs.length > 0) {
          buildColHeaderHeaders(thead, colHeaderHeaders, rowAttrs, colAttrs);
          node = {
            counter: 0
          };
          ref10 = colHeaders.children;
          for (k = 0, len = ref10.length; k < len; k++) {
            chKey = ref10[k];
            buildColHeader(colHeaderHeaders, colHeaderCols, colHeaders[chKey], rowAttrs, colAttrs, node);
          }
          buildColHeaderHeadersClickEvents(colHeaderHeaders, colHeaderCols, colAttrs);
        }
        if (rowAttrs.length > 0) {
          buildRowHeaderHeaders(thead, rowHeaderHeaders, rowAttrs, colAttrs);
          if (colAttrs.length === 0) {
            buildRowTotalsHeader(rowHeaderHeaders.tr, rowAttrs, colAttrs);
          }
        }
        if (colAttrs.length > 0) {
          buildRowTotalsHeader(colHeaderHeaders[0].tr, rowAttrs, colAttrs);
        }
        tbody = createElement("tbody");
        result.appendChild(tbody);
        node = {
          counter: 0
        };
        if (rowAttrs.length > 0) {
          ref11 = rowHeaders.children;
          for (l = 0, len1 = ref11.length; l < len1; l++) {
            chKey = ref11[l];
            buildRowHeader(tbody, rowHeaderHeaders, rowHeaderRows, rowHeaders[chKey], rowAttrs, colAttrs, node);
          }
        }
        buildRowHeaderHeadersClickEvents(rowHeaderHeaders, rowHeaderRows, rowAttrs);
        tr = buildColTotalsHeader(rowAttrs, colAttrs);
        if (colAttrs.length > 0) {
          buildColTotals(tr, colHeaderCols);
        }
        buildGrandTotal(tbody, tr);
        result.setAttribute("data-numrows", rowKeys.length);
        result.setAttribute("data-numcols", colKeys.length);
        result.style.display = "";
        return result;
      };
      return main(rowAttrs, rowKeys, colAttrs, colKeys);
    };
    $.pivotUtilities.subtotal_renderers = {
      "Table With Subtotal": function(pvtData, opts) {
        return SubtotalRenderer(pvtData, opts);
      },
      "Table With Subtotal Bar Chart": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).barchart();
      },
      "Table With Subtotal Heatmap": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).heatmap("heatmap", opts);
      },
      "Table With Subtotal Row Heatmap": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).heatmap("rowheatmap", opts);
      },
      "Table With Subtotal Col Heatmap": function(pvtData, opts) {
        return $(SubtotalRenderer(pvtData, opts)).heatmap("colheatmap", opts);
      }
    };
    usFmtPct = $.pivotUtilities.numberFormat({
      digitsAfterDecimal: 1,
      scaler: 100,
      suffix: "%"
    });
    aggregatorTemplates = $.pivotUtilities.aggregatorTemplates;
    subtotalAggregatorTemplates = {
      fractionOf: function(wrapped, type, formatter) {
        if (type == null) {
          type = "row";
        }
        if (formatter == null) {
          formatter = usFmtPct;
        }
        return function() {
          var x;
          x = 1 <= arguments.length ? slice.call(arguments, 0) : [];
          return function(data, rowKey, colKey) {
            if (typeof rowKey === "undefined") {
              rowKey = [];
            }
            if (typeof colKey === "undefined") {
              colKey = [];
            }
            return {
              selector: {
                row: [rowKey.slice(0, -1), []],
                col: [[], colKey.slice(0, -1)]
              }[type],
              inner: wrapped.apply(null, x)(data, rowKey, colKey),
              push: function(record) {
                return this.inner.push(record);
              },
              format: formatter,
              value: function() {
                return this.inner.value() / data.getAggregator.apply(data, this.selector).inner.value();
              },
              numInputs: wrapped.apply(null, x)().numInputs
            };
          };
        };
      }
    };
    $.pivotUtilities.subtotalAggregatorTemplates = subtotalAggregatorTemplates;
    return $.pivotUtilities.subtotal_aggregators = (function(tpl, sTpl) {
      return {
        "Sum As Fraction Of Parent Row": sTpl.fractionOf(tpl.sum(), "row", usFmtPct),
        "Sum As Fraction Of Parent Column": sTpl.fractionOf(tpl.sum(), "col", usFmtPct),
        "Count As Fraction Of Parent Row": sTpl.fractionOf(tpl.count(), "row", usFmtPct),
        "Count As Fraction Of Parent Column": sTpl.fractionOf(tpl.count(), "col", usFmtPct)
      };
    })(aggregatorTemplates, subtotalAggregatorTemplates);
  });

}).call(this);

//# sourceMappingURL=subtotal.js.map
