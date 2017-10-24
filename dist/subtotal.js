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
      var addClass, adjustAxisHeader, allTotal, arrowCollapsed, arrowExpanded, buildAxisHeader, buildColAxisHeaders, buildColHeader, buildColTotals, buildColTotalsHeader, buildGrandTotal, buildRowAxisHeaders, buildRowHeader, buildRowTotalsHeader, buildValues, classColHide, classColShow, classCollapsed, classExpanded, classRowHide, classRowShow, clickStatusCollapsed, clickStatusExpanded, colAttrs, colKeys, colTotals, collapseAxis, collapseChildCol, collapseChildRow, collapseCol, collapseRow, collapseShowColSubtotal, collapseShowRowSubtotal, createElement, defaults, expandAxis, expandChildCol, expandChildRow, expandCol, expandHideColSubtotal, expandHideRowSubtotal, expandRow, expandShowColSubtotal, expandShowRowSubtotal, getTableEventHandlers, hasClass, hideDescendantCol, hideDescendantRow, main, processKeys, removeClass, replaceClass, rowAttrs, rowKeys, rowTotals, setAttributes, setHeaderAttribs, showChildCol, showChildRow, tree;
      defaults = {
        table: {
          clickCallback: null
        },
        localeStrings: {
          totals: "Totals"
        }
      };
      opts = $.extend(true, {}, defaults, opts);
      if (!opts.rowSubtotalDisplay) {
        opts.rowSubtotalDisplay = {};
      }
      if (typeof opts.rowSubtotalDisplay.disableFrom === 'undefined') {
        if (!opts.rowSubtotalDisplay.disableSubtotal) {
          if (typeof opts.rowSubtotalDisplay.disableAfter === 'undefined') {
            opts.rowSubtotalDisplay.disableFrom = 9999;
          } else {
            opts.rowSubtotalDisplay.disableFrom = opts.rowSubtotalDisplay.disableAfter + 1;
          }
        } else {
          opts.rowSubtotalDisplay.disableFrom = 0;
        }
      }
      if (typeof opts.rowSubtotalDisplay.collapseAt === 'undefined') {
        if (typeof opts.collapseRowsAt === 'undefined') {
          opts.rowSubtotalDisplay.collapseAt = 9999;
        } else {
          opts.rowSubtotalDisplay.collapseAt = opts.collapseRowsAt;
        }
      }
      if (!opts.colSubtotalDisplay) {
        opts.colSubtotalDisplay = {};
      }
      if (typeof opts.colSubtotalDisplay.disableFrom === 'undefined') {
        if (!opts.colSubtotalDisplay.disableSubtotal) {
          if (typeof opts.colSubtotalDisplay.disableAfter === 'undefined') {
            opts.colSubtotalDisplay.disableFrom = 9999;
          } else {
            opts.colSubtotalDisplay.disableFrom = opts.colSubtotalDisplay.disableAfter + 1;
          }
        } else {
          opts.colSubtotalDisplay.disableFrom = 0;
        }
      }
      if (typeof opts.colSubtotalDisplay.collapseAt === 'undefined') {
        if (typeof opts.collapseColsAt === 'undefined') {
          opts.colSubtotalDisplay.collapseAt = 9999;
        } else {
          opts.colSubtotalDisplay.collapseAt = opts.collapseColsAt;
        }
      }
      arrowCollapsed = opts.arrowCollapsed != null ? opts.arrowCollapsed : opts.arrowCollapsed = "\u25B6";
      arrowExpanded = opts.arrowExpanded != null ? opts.arrowExpanded : opts.arrowExpanded = "\u25E2";
      colAttrs = pivotData.colAttrs;
      rowAttrs = pivotData.rowAttrs;
      rowKeys = pivotData.getRowKeys();
      colKeys = pivotData.getColKeys();
      tree = pivotData.tree;
      rowTotals = pivotData.rowTotals;
      colTotals = pivotData.colTotals;
      allTotal = pivotData.allTotal;
      classRowHide = "rowhide";
      classRowShow = "rowshow";
      classColHide = "colhide";
      classColShow = "colshow";
      clickStatusExpanded = "expanded";
      clickStatusCollapsed = "collapsed";
      classExpanded = "expanded";
      classCollapsed = "collapsed";
      opts.rowSubtotalDisplay.displayOnTop = true;
      hasClass = function(element, className) {
        var regExp;
        regExp = new RegExp("(?:^|\\s)" + className + "(?!\\S)", "g");
        return element.className.match(regExp) !== null;
      };
      removeClass = function(element, className) {
        var k, len, name, ref, regExp, results;
        ref = className.split(" ");
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          name = ref[k];
          regExp = new RegExp("(?:^|\\s)" + name + "(?!\\S)", "g");
          results.push(element.className = element.className.replace(regExp, ''));
        }
        return results;
      };
      addClass = function(element, className) {
        var k, len, name, ref, results;
        ref = className.split(" ");
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          name = ref[k];
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
        var attr, event, eventHandlers, filters, handler, i, ref;
        if (!opts.table && !opts.table.eventHandlers) {
          return;
        }
        eventHandlers = {};
        ref = opts.table.eventHandlers;
        for (event in ref) {
          if (!hasProp.call(ref, event)) continue;
          handler = ref[event];
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
      processKeys = function(keysArr, className, opts) {
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
              var i, k, key, node, ref;
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
                for (i = k = 0, ref = lastIdx - 1; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
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
        console.warn(tree);
        return tree;
      };
      buildAxisHeader = function(axisHeaders, col, attrs, opts) {
        var ah, arrow, hClass;
        ah = {
          text: attrs[col],
          expandedCount: 0,
          expandables: 0,
          attrHeaders: [],
          clickStatus: clickStatusExpanded,
          onClick: collapseAxis
        };
        arrow = arrowExpanded + " ";
        hClass = classExpanded;
        if (col > opts.collapseAt) {
          arrow = arrowCollapsed + " ";
          hClass = classCollapsed;
          ah.clickStatus = clickStatusCollapsed;
          ah.onClick = expandAxis;
        }
        if (col === attrs.length - 1 || col >= opts.disableFrom || opts.disableExpandCollapse) {
          arrow = "";
        }
        ah.th = createElement("th", "pvtAxisLabel " + hClass, "" + arrow + ah.text);
        ah.th.onclick = function(event) {
          event = event || window.event;
          return ah.onClick(axisHeaders, col, attrs, opts);
        };
        axisHeaders.ah.push(ah);
        return ah;
      };
      buildColAxisHeaders = function(thead, rowAttrs, colAttrs, opts) {
        var ah, attr, axisHeaders, col, k, len;
        axisHeaders = {
          collapseAttrHeader: collapseCol,
          expandAttrHeader: expandCol,
          ah: []
        };
        for (col = k = 0, len = colAttrs.length; k < len; col = ++k) {
          attr = colAttrs[col];
          ah = buildAxisHeader(axisHeaders, col, colAttrs, opts.colSubtotalDisplay);
          ah.tr = createElement("tr");
          if (col === 0 && rowAttrs.length !== 0) {
            ah.tr.appendChild(createElement("th", null, null, {
              colspan: rowAttrs.length,
              rowspan: colAttrs.length
            }));
          }
          ah.tr.appendChild(ah.th);
          thead.appendChild(ah.tr);
        }
        return axisHeaders;
      };
      buildRowAxisHeaders = function(thead, rowAttrs, colAttrs, opts) {
        var ah, axisHeaders, col, k, ref, th;
        axisHeaders = {
          collapseAttrHeader: collapseRow,
          expandAttrHeader: expandRow,
          ah: [],
          tr: createElement("tr")
        };
        for (col = k = 0, ref = rowAttrs.length - 1; 0 <= ref ? k <= ref : k >= ref; col = 0 <= ref ? ++k : --k) {
          ah = buildAxisHeader(axisHeaders, col, rowAttrs, opts.rowSubtotalDisplay);
          axisHeaders.tr.appendChild(ah.th);
        }
        if (colAttrs.length !== 0) {
          th = createElement("th");
          axisHeaders.tr.appendChild(ah.th);
        }
        thead.appendChild(axisHeaders.tr);
        return axisHeaders;
      };
      setHeaderAttribs = function(col, label, collapse, expand, attrs, opts) {
        var hProps;
        hProps = {
          arrow: arrowExpanded,
          clickStatus: clickStatusExpanded,
          onClick: collapse,
          "class": classExpanded + " "
        };
        if (col > opts.collapseAt) {
          hProps = {
            arrow: arrowCollapsed,
            clickStatus: clickStatusCollapsed,
            onClick: expand,
            "class": classCollapsed + " "
          };
        }
        if (col === attrs.length - 1 || col >= opts.disableFrom || opts.disableExpandCollapse) {
          hProps.arrow = "";
        }
        hProps.textContent = hProps.arrow + " " + label;
        return hProps;
      };
      buildColHeader = function(axisHeaders, attrHeaders, h, rowAttrs, colAttrs, node, opts) {
        var ah, chKey, hProps, k, len, ref, ref1;
        ref = h.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          buildColHeader(axisHeaders, attrHeaders, h[chKey], rowAttrs, colAttrs, node, opts);
        }
        ah = axisHeaders.ah[h.col];
        ah.attrHeaders.push(h);
        h.node = node.counter;
        hProps = setHeaderAttribs(h.col, h.text, collapseCol, expandCol, colAttrs, opts.colSubtotalDisplay);
        h.onClick = hProps.onClick;
        addClass(h.th, classColShow + " col" + h.row + " colcol" + h.col + " " + hProps["class"]);
        h.th.setAttribute("data-colnode", h.node);
        if (h.children.length !== 0) {
          h.th.colSpan = h.childrenSpan;
        }
        if (h.children.length === 0 && rowAttrs.length !== 0) {
          h.th.rowSpan = 2;
        }
        h.th.textContent = hProps.textContent;
        if (h.leaves > 1 && h.col < opts.colSubtotalDisplay.disableFrom && !opts.colSubtotalDisplay.disableExpandCollapse) {
          ah.expandables++;
          if (h.col < opts.colSubtotalDisplay.collapseAt) {
            ah.expandedCount += 1;
          }
          h.th.onclick = function(event) {
            event = event || window.event;
            return h.onClick(axisHeaders, h, opts.colSubtotalDisplay);
          };
          h.sTh = createElement("th", "pvtColLabelFiller col" + h.row + " colcol" + h.col + " " + hProps["class"]);
          h.sTh.setAttribute("data-colnode", h.node);
          h.sTh.rowSpan = colAttrs.length - h.col;
          if ((opts.colSubtotalDisplay.hideOnExpand && h.col < opts.colSubtotalDisplay.collapseAt) || h.col > opts.colSubtotalDisplay.collapseAt) {
            h.sTh.style.display = "none";
          }
          if (h.children.length !== 0) {
            h[h.children[0]].tr.appendChild(h.sTh);
          }
          h.th.colSpan++;
        }
        if ((ref1 = h.parent) != null) {
          ref1.childrenSpan += h.th.colSpan;
        }
        h.clickStatus = hProps.clickStatus;
        ah.tr.appendChild(h.th);
        h.tr = ah.tr;
        attrHeaders.push(h);
        return node.counter++;
      };
      buildRowTotalsHeader = function(tr, rowAttrs, colAttrs) {
        var th;
        th = createElement("th", "pvtTotalLabel rowTotal", opts.localeStrings.totals, {
          rowspan: colAttrs.length === 0 ? 1 : colAttrs.length + (rowAttrs.length === 0 ? 0 : 1)
        });
        return tr.appendChild(th);
      };
      buildRowHeader = function(tbody, axisHeaders, attrHeaders, h, rowAttrs, colAttrs, node, opts) {
        var ah, chKey, firstChild, hProps, k, len, ref, ref1;
        ref = h.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          buildRowHeader(tbody, axisHeaders, attrHeaders, h[chKey], rowAttrs, colAttrs, node, opts);
        }
        ah = axisHeaders.ah[h.col];
        ah.attrHeaders.push(h);
        h.node = node.counter;
        hProps = setHeaderAttribs(h.col, h.text, collapseRow, expandRow, rowAttrs, opts.rowSubtotalDisplay);
        h.onClick = hProps.onClick;
        if (h.children.length !== 0) {
          firstChild = h[h.children[0]];
        }
        addClass(h.th, classRowShow + " row" + h.row + " rowcol" + h.col + " " + hProps["class"]);
        h.th.setAttribute("data-rownode", h.node);
        if (h.col === rowAttrs.length - 1 && colAttrs.length !== 0) {
          h.th.colSpan = 2;
        }
        if (h.children.length !== 0) {
          h.th.rowSpan = h.childrenSpan;
        }
        h.th.textContent = hProps.textContent;
        if (h.leaves === 1) {
          h.tr = firstChild.tr;
          h.tr.insertBefore(h.th, firstChild.th);
          h.sTh = firstChild.sTh;
        } else {
          h.tr = createElement("tr", "row" + h.row);
          h.tr.appendChild(h.th);
          if (h.leaves === 0) {
            tbody.appendChild(h.tr);
          }
        }
        if (h.leaves > 1 && h.col < opts.rowSubtotalDisplay.disableFrom) {
          if (h.col < opts.rowSubtotalDisplay.collapseAt) {
            ++ah.expandedCount;
          }
          if (!opts.rowSubtotalDisplay.disableExpandCollapse) {
            ++ah.expandables;
            addClass(h.th, hProps["class"]);
            h.th.textContent = hProps.arrow + " " + h.text;
            h.th.onclick = function(event) {
              event = event || window.event;
              return h.onClick(axisHeaders, h, opts.rowSubtotalDisplay);
            };
          }
          h.sTh = createElement("th", "pvtRowLabelFiller row" + h.row + " rowcol" + h.col + " " + hProps["class"]);
          h.sTh.setAttribute("data-rownode", h.node);
          h.sTh.colSpan = rowAttrs.length - (h.col + 1) + (colAttrs.length !== 0 ? 1 : 0);
          if ((opts.rowSubtotalDisplay.hideOnExpand && h.col < opts.rowSubtotalDisplay.collapseAt) || h.col > opts.rowSubtotalDisplay.collapseAt) {
            h.sTh.style.display = "none";
          }
          h.th.rowSpan++;
          addClass(h.tr, hProps["class"]);
          if (opts.rowSubtotalDisplay.displayOnTop) {
            h.tr.appendChild(h.sTh);
          } else {
            h.sTr = createElement("tr", "row" + h.row + " " + hProps["class"]);
            h.sTr.appendChild(h.sTh);
            tbody.appendChild(h.sTr);
          }
          tbody.insertBefore(h.tr, firstChild.tr);
        }
        if ((ref1 = h.parent) != null) {
          ref1.childrenSpan += h.th.rowSpan;
        }
        h.clickStatus = hProps.clickStatus;
        attrHeaders.push(h);
        return node.counter++;
      };
      buildValues = function(tbody, colAttrHeaders, rowAttrHeaders) {
        var aggregator, colHeader, colInit, eventHandlers, flatColKey, flatRowKey, isColSubtotal, isRowSubtotal, k, l, len, len1, ref, results, rowHeader, rowInit, style, td, totalAggregator, val;
        results = [];
        for (k = 0, len = attrHeaders.length; k < len; k++) {
          rowHeader = attrHeaders[k];
          rowInit = setRowInitParams(rowHeader.col);
          flatRowKey = rowHeader.flatKey;
          isRowSubtotal = rowHeader.descendants !== 0;
          for (l = 0, len1 = attrHeaders.length; l < len1; l++) {
            colHeader = attrHeaders[l];
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
            isColSubtotal = colHeader.descendants !== 0;
            colInit = setColInitParams(colHeader.col);
            style = "pvtVal";
            if (isColSubtotal) {
              style += " pvtColSubtotal " + colInit.colClass;
            }
            if (isRowSubtotal) {
              style += " pvtRowSubtotal " + rowInit.rowClass;
            }
            style += (isRowSubtotal && (rowHeader.col >= rowDisableFrom || (isRowHideOnExpand && rowHeader.col < opts.rowSubtotalDisplay.collapseAt))) || (rowHeader.col > opts.rowSubtotalDisplay.collapseAt) ? " " + classRowHide : " " + classRowShow;
            style += (isColSubtotal && (isColDisable || colHeader.col > colDisableAfter || (isColHideOnExpand && colHeader.col < opts.colSubtotalDisplay.collapseAt))) || (colHeader.col > opts.colSubtotalDisplay.collapseAt) ? " " + classColHide : " " + classColShow;
            style += (" row" + rowHeader.row) + (" col" + colHeader.row) + (" rowcol" + rowHeader.col) + (" colcol" + colHeader.col);
            eventHandlers = getTableEventHandlers(val, rowHeader.key, colHeader.key);
            td = createElement("td", style, aggregator.format(val), {
              "data-value": val,
              "data-rownode": rowHeader.node,
              "data-colnode": colHeader.node
            }, eventHandlers);
            if (!isDisplayOnTop) {
              if ((rowHeader.col > opts.rowSubtotalDisplay.collapseAt || colHeader.col > opts.colSubtotalDisplay.collapseAt) || (isRowSubtotal && (rowHeader.col >= rowDisableFrom || (isRowHideOnExpand && rowHeader.col < opts.rowSubtotalDisplay.collapseAt))) || (isColSubtotal && (isColDisable || colHeader.col > colDisableAfter || (isColHideOnExpand && colHeader.col < opts.colSubtotalDisplay.collapseAt)))) {
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
          style += isRowSubtotal && (rowHeader.col >= rowDisableFrom || !isDisplayOnTop || (isRowHideOnExpand && rowHeader.col < opts.rowSubtotalDisplay.collapseAt)) ? " " + classRowHide : " " + classRowShow;
          style += " row" + rowHeader.row + " rowcol" + rowHeader.col;
          td = createElement("td", style, totalAggregator.format(val), {
            "data-value": val,
            "data-row": "row" + rowHeader.row,
            "data-rowcol": "col" + rowHeader.col,
            "data-rownode": rowHeader.node
          }, getTableEventHandlers(val, rowHeader.key, []));
          if (!isDisplayOnTop) {
            if ((rowHeader.col > opts.rowSubtotalDisplay.collapseAt) || (isRowSubtotal && (rowHeader.col >= rowDisableFrom || (isRowHideOnExpand && rowHeader.col < opts.rowSubtotalDisplay.collapseAt)))) {
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
      buildColTotals = function(tr, attrHeaders) {
        var clsNames, colInit, h, k, len, results, td, totalAggregator, val;
        results = [];
        for (k = 0, len = attrHeaders.length; k < len; k++) {
          h = attrHeaders[k];
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
          if ((h.col > opts.colSubtotalDisplay.collapseAt) || (h.children.length !== 0 && (isColDisable || h.col > colDisableAfter || (isColHideOnExpand && h.col < opts.colSubtotalDisplay.collapseAt)))) {
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
      adjustAxisHeader = function(axisHeaders, col, opts) {
        var ah;
        ah = axisHeaders.ah[col];
        if (ah.expandedCount === 0) {
          replaceClass(ah.th, classExpanded, classCollapsed);
          ah.th.textContent = " " + arrowCollapsed + " " + ah.text;
          ah.clickStatus = clickStatusCollapsed;
          return ah.onClick = expandAxis;
        } else if (ah.expandedCount === ah.expandables) {
          replaceClass(ah.th, classCollapsed, classExpanded);
          ah.th.textContent = " " + arrowExpanded + " " + ah.text;
          ah.clickStatus = clickStatusExpanded;
          return ah.onClick = collapseAxis;
        }
      };
      hideDescendantCol = function(d) {
        return $(d.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + d.node + "\"], th[data-colnode=\"" + d.node + "\"]").removeClass(classColShow).addClass(classColHide).css('display', "none");
      };
      collapseShowColSubtotal = function(h) {
        $(h.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + h.node + "\"], th[data-colnode=\"" + h.node + "\"]").removeClass(classExpanded + " " + classColHide).addClass(classCollapsed + " " + classColShow).not(".pvtRowSubtotal." + classRowHide).css('display', "");
        h.th.textContent = " " + arrowCollapsed + " " + h.text;
        return h.th.colSpan = 1;
      };
      collapseChildCol = function(ch, h) {
        var chKey, k, len, ref;
        ref = ch.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          collapseChildCol(ch[chKey], h);
        }
        return hideDescendantCol(ch);
      };
      collapseCol = function(axisHeaders, h, opts) {
        var chKey, colSpan, k, len, p, ref;
        colSpan = h.th.colSpan - 1;
        ref = h.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          collapseChildCol(h[chKey], h);
        }
        collapseShowColSubtotal(h);
        p = h.parent;
        while (p) {
          p.th.colSpan -= colSpan;
          p = p.parent;
        }
        h.clickStatus = clickStatusCollapsed;
        h.onClick = expandCol;
        axisHeaders.ah[h.col].expandedCount--;
        return adjustAxisHeader(axisHeaders, h.col, opts);
      };
      showChildCol = function(ch) {
        return $(ch.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + ch.node + "\"], th[data-colnode=\"" + ch.node + "\"]").removeClass(classColHide).addClass(classColShow).not(".pvtRowSubtotal." + classRowHide).css('display', "");
      };
      expandHideColSubtotal = function(h) {
        $(h.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + h.node + "\"], th[data-colnode=\"" + h.node + "\"]").removeClass(classCollapsed + " " + classColShow).addClass(classExpanded + " " + classColHide).css('display', "none");
        return h.th.style.display = "";
      };
      expandShowColSubtotal = function(h) {
        $(h.th).closest('table.pvtTable').find("tbody tr td[data-colnode=\"" + h.node + "\"], th[data-colnode=\"" + h.node + "\"]").removeClass(classCollapsed + " " + classColHide).addClass(classExpanded + " " + classColShow).not(".pvtRowSubtotal." + classRowHide).css('display', "");
        h.th.style.display = "";
        ++h.th.colSpan;
        if (h.sTh != null) {
          return h.sTh.style.display = "";
        }
      };
      expandChildCol = function(ch, opts) {
        var chKey, k, len, ref, results;
        if (ch.leaves !== 0 && ch.clickStatus === clickStatusCollapsed && (ch.col >= opts.disableFrom || opts.hideOnExpand)) {
          ch.th.style.display = "";
        } else {
          showChildCol(ch);
        }
        if (ch.clickStatus === clickStatusExpanded) {
          ref = ch.children;
          results = [];
          for (k = 0, len = ref.length; k < len; k++) {
            chKey = ref[k];
            results.push(expandChildCol(ch[chKey], opts));
          }
          return results;
        }
      };
      expandCol = function(axisHeaders, h, opts) {
        var ch, chKey, colSpan, k, len, p, ref;
        colSpan = 0;
        ref = h.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          ch = h[chKey];
          expandChildCol(ch, opts);
          colSpan += ch.th.colSpan;
        }
        h.th.colSpan = colSpan;
        if (h.children.length !== 0) {
          replaceClass(h.th, classCollapsed, classExpanded);
          h.th.textContent = " " + arrowExpanded + " " + h.text;
          if (opts.hideOnExpand) {
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
        h.onClick = collapseCol;
        axisHeaders.ah[h.col].expandedCount++;
        return adjustAxisHeader(axisHeaders, h.col, opts);
      };
      hideDescendantRow = function(d, opts) {
        var cell, cells, k, l, len, len1;
        if (opts.displayOnTop) {
          d.tr.style.display = "none";
        }
        cells = d.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          replaceClass(cell, classRowShow, classRowHide);
        }
        if (!opts.displayOnTop) {
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
          removeClass(cell, classExpanded + " " + classRowHide);
          addClass(cell, classCollapsed + " " + classRowShow);
          if (!hasClass(cell, classColHide)) {
            cell.style.display = "";
          }
        }
        replaceClass(h.sTh, classExpanded, classCollapsed);
        h.th.rowSpan = 1;
        replaceClass(h.tr, classExpanded, classCollapsed);
        return h.tr.style.display = "";
      };
      collapseChildRow = function(ch, h, opts) {
        var chKey, k, len, ref;
        ref = ch.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          collapseChildRow(ch[chKey], h, opts);
        }
        return hideDescendantRow(ch, opts);
      };
      collapseRow = function(axisHeaders, h, opts) {
        var chKey, k, len, p, ref, rowSpan;
        rowSpan = h.th.rowSpan - 1;
        ref = h.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          collapseChildRow(h[chKey], h, opts);
        }
        if (h.leaves > 1) {
          collapseShowRowSubtotal(h);
        }
        if (opts.displayOnTop) {
          p = h.parent;
          while (p) {
            p.th.rowSpan -= rowSpan;
            p = p.parent;
          }
        }
        h.clickStatus = clickStatusCollapsed;
        h.onClick = expandRow;
        return adjustAxisHeader(axisHeaders, h.col, opts);
      };
      showChildRow = function(h, opts) {
        var cell, cells, k, l, len, len1;
        cells = h.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          replaceClass(cell, classRowHide, classRowShow);
        }
        if (!opts.displayOnTop) {
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
          removeClass(cell, classCollapsed + " " + classRowHide);
          addClass(cell, classExpanded + " " + classRowShow);
          if (!hasClass(cell, classColHide)) {
            cell.style.display = "";
          }
        }
        h.sTh.style.display = "";
        replaceClass(h.sTh, classCollapsed, classExpanded);
        h.th.style.display = "";
        replaceClass(h.th, classCollapsed, classExpanded);
        replaceClass(h.tr, classCollapsed, classExpanded);
        return h.tr.style.display = "";
      };
      expandHideRowSubtotal = function(h) {
        var cell, cells, k, len;
        cells = h.tr.getElementsByTagName("td");
        for (k = 0, len = cells.length; k < len; k++) {
          cell = cells[k];
          removeClass(cell, classCollapsed + " " + classRowShow);
          addClass(cell, classExpanded + " " + classRowHide);
        }
        h.th.textContent = " " + arrowExpanded + " " + h.text;
        h.th.style.display = "";
        replaceClass(h.tr, classCollapsed, classExpanded);
        return h.tr.style.display = "none";
      };
      expandChildRow = function(ch, opts) {
        var chKey, k, len, ref, results;
        showChildRow(ch, opts);
        ref = ch.children;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          if (ch.clickStatus === clickStatusExpanded) {
            results.push(expandChildRow(ch[chKey], opts));
          }
        }
        return results;
      };
      expandRow = function(axisHeaders, h, opts) {
        var ch, chKey, k, len, p, ref, rowSpan;
        rowSpan = 0;
        ref = h.children;
        for (k = 0, len = ref.length; k < len; k++) {
          chKey = ref[k];
          ch = h[chKey];
          expandChildRow(ch, opts);
          rowSpan += ch.th.rowSpan;
        }
        if (h.leaves > 1) {
          if (opts.hideOnExpand) {
            expandHideRowSubtotal(h);
          } else {
            expandShowRowSubtotal(h);
          }
        }
        if (opts.displayOnTop) {
          h.th.rowSpan = rowSpan + 1;
          p = h.parent;
          while (p) {
            p.th.rowSpan += rowSpan;
            p = p.parent;
          }
        }
        h.clickStatus = clickStatusExpanded;
        h.onClick = collapseRow;
        return adjustAxisHeader(axisHeaders, h.col, opts);
      };
      collapseAxis = function(axisHeaders, col, attrs, opts) {
        var ah, h, k, len, ref, results;
        ah = axisHeaders.ah[col];
        ref = ah.attrHeaders;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          h = ref[k];
          if (h.clickStatus !== clickStatusCollapsed && h.th.style.display !== "none" && h.leaves > 1) {
            results.push(axisHeaders.collapseAttrHeader(axisHeaders, h, opts));
          }
        }
        return results;
      };
      expandAxis = function(axisHeaders, col, attrs, opts) {
        var ah, h, i, k, ref, results;
        results = [];
        for (i = k = 0, ref = col; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
          ah = axisHeaders.ah[i];
          results.push((function() {
            var l, len, ref1, results1;
            ref1 = ah.attrHeaders;
            results1 = [];
            for (l = 0, len = ref1.length; l < len; l++) {
              h = ref1[l];
              if (h.clickStatus !== clickStatusExpanded && h.leaves > 1) {
                results1.push(axisHeaders.expandAttrHeader(axisHeaders, h, opts));
              }
            }
            return results1;
          })());
        }
        return results;
      };
      main = function(rowAttrs, rowKeys, colAttrs, colKeys) {
        var chKey, colAttrHeaders, colAxisHeaders, colKeyHeaders, k, l, len, len1, node, ref, ref1, result, rowAttrHeaders, rowAxisHeaders, rowKeyHeaders, tbody, thead, tr;
        rowAttrHeaders = [];
        colAttrHeaders = [];
        if (colAttrs.length !== 0 && colKeys.length !== 0) {
          colKeyHeaders = processKeys(colKeys, "pvtColLabel");
        }
        if (rowAttrs.length !== 0 && rowKeys.length !== 0) {
          rowKeyHeaders = processKeys(rowKeys, "pvtRowLabel");
        }
        result = createElement("table", "pvtTable", null, {
          style: "display: none;"
        });
        thead = createElement("thead");
        result.appendChild(thead);
        if (colAttrs.length !== 0) {
          colAxisHeaders = buildColAxisHeaders(thead, rowAttrs, colAttrs, opts);
          node = {
            counter: 0
          };
          ref = colKeyHeaders.children;
          for (k = 0, len = ref.length; k < len; k++) {
            chKey = ref[k];
            buildColHeader(colAxisHeaders, colAttrHeaders, colKeyHeaders[chKey], rowAttrs, colAttrs, node, opts);
          }
          buildRowTotalsHeader(colAxisHeaders.ah[0].tr, rowAttrs, colAttrs);
        }
        tbody = createElement("tbody");
        result.appendChild(tbody);
        if (rowAttrs.length !== 0) {
          rowAxisHeaders = buildRowAxisHeaders(thead, rowAttrs, colAttrs, opts);
          if (colAttrs.length === 0) {
            buildRowTotalsHeader(rowAxisHeaders.tr, rowAttrs, colAttrs);
          }
          node = {
            counter: 0
          };
          ref1 = rowKeyHeaders.children;
          for (l = 0, len1 = ref1.length; l < len1; l++) {
            chKey = ref1[l];
            buildRowHeader(tbody, rowAxisHeaders, rowAttrHeaders, rowKeyHeaders[chKey], rowAttrs, colAttrs, node, opts);
          }
        }
        tr = buildColTotalsHeader(rowAttrs, colAttrs);
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
