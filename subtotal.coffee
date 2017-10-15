callWithJQuery = (pivotModule) ->
    if typeof exports is "object" and typeof module is "object" # CommonJS
        pivotModule require("jquery")
    else if typeof define is "function" and define.amd # AMD
        define ["jquery"], pivotModule
    # Plain browser env
    else
        pivotModule jQuery

callWithJQuery ($) ->

    class SubtotalPivotData extends $.pivotUtilities.PivotData
        constructor: (input, opts) ->
            super input, opts

        processKey = (record, totals, keys, attrs, getAggregator) ->
            key = []
            addKey = false
            for attr in attrs
                key.push record[attr] ? "null"
                flatKey = key.join String.fromCharCode(0)
                if not totals[flatKey]
                    totals[flatKey] = getAggregator key.slice()
                    addKey = true
                totals[flatKey].push record
            keys.push key if addKey
            return key

        processRecord: (record) -> #this code is called in a tight loop
            rowKey = []
            colKey = []

            @allTotal.push record
            rowKey = processKey record, @rowTotals, @rowKeys, @rowAttrs, (key) =>
                return @aggregator this, key, []
            colKey = processKey record, @colTotals, @colKeys, @colAttrs, (key) =>
                return @aggregator this, [], key
            m = rowKey.length-1
            n = colKey.length-1
            return if m < 0 or n < 0
            for i in [0..m]
                fRowKey = rowKey.slice(0, i+1)
                flatRowKey = fRowKey.join String.fromCharCode(0)
                @tree[flatRowKey] = {} if not @tree[flatRowKey]
                for j in [0..n]
                    fColKey = colKey.slice 0, j+1
                    flatColKey = fColKey.join String.fromCharCode(0)
                    @tree[flatRowKey][flatColKey] = @aggregator this, fRowKey, fColKey if not @tree[flatRowKey][flatColKey]
                    @tree[flatRowKey][flatColKey].push record

    $.pivotUtilities.SubtotalPivotData = SubtotalPivotData

    SubtotalRenderer = (pivotData, opts) ->
        defaults =
            table: clickCallback: null
            localeStrings: totals: "Totals"

        opts = $.extend true, {}, defaults, opts

        isRowDisable = opts.rowSubtotalDisplay?.disableSubtotal
        rowDisableAfter = if typeof opts.rowSubtotalDisplay?.disableAfter isnt 'undefined' then opts.rowSubtotalDisplay.disableAfter else 9999
        if typeof opts.rowSubtotalDisplay?disableFrom is 'undefined'
            rowDisableFrom = if isRowDisable then 0 else rowDisableAfter + 1
        else
            rowDisableFrom = opts.rowSubtotalDisplay.disableFrom
        isRowHideOnExpand = opts.rowSubtotalDisplay?.hideOnExpand
        isRowDisableExpandCollapse = opts.rowSubtotalDisplay?.disableExpandCollapse
        isDisplayOnTop = if typeof opts.rowSubtotalDisplay?.displayOnTop isnt 'undefined' then opts.rowSubtotalDisplay.displayOnTop else true
        isColDisable = opts.colSubtotalDisplay?.disableSubtotal
        isColHideOnExpand = opts.colSubtotalDisplay?.hideOnExpand
        isColDisableExpandCollapse = opts.colSubtotalDisplay?.disableExpandCollapse
        colDisableAfter = if typeof opts.colSubtotalDisplay?.disableAfter isnt 'undefined' then opts.colSubtotalDisplay.disableAfter else 9999
        if typeof opts.colSubtotalDisplay?disableFrom is 'undefined'
            colDisableFrom = if isColDisable then 0 else colDisableAfter + 1
        else
            colDisableFrom = opts.colSubtotalDisplay.disableFrom
        isDisplayOnRight = if typeof opts.colSubtotalDisplay?.displayOnRight isnt 'undefined' then opts.rowSubtotalDisplay.displayOnRight else true
        arrowCollapsed = opts.arrowCollapsed ?= "\u25B6"
        arrowExpanded = opts.arrowExpanded ?= "\u25E2"
        colsCollapseAt = if typeof opts.collapseColsAt isnt 'undefined' then opts.collapseColsAt else 9999
        rowsCollapseAt = if typeof opts.collapseRowsAt isnt 'undefined' then opts.collapseRowsAt else 9999

        colAttrs = pivotData.colAttrs
        rowAttrs = pivotData.rowAttrs
        rowKeys = pivotData.getRowKeys()
        colKeys = pivotData.getColKeys()
        tree = pivotData.tree
        rowTotals = pivotData.rowTotals
        colTotals = pivotData.colTotals
        allTotal = pivotData.allTotal

        classRowExpanded = "rowexpanded"
        classRowCollapsed = "rowcollapsed"
        classRowHide = "rowhide"
        classRowShow = "rowshow"
        classColExpanded = "colexpanded"
        classColCollapsed = "colcollapsed"
        classColHide = "colhide"
        classColShow = "colshow"
        clickStatusExpanded = "expanded"
        clickStatusCollapsed = "collapsed"
        classExpanded = "expanded"
        classCollapsed = "collapsed"


        isDisplayOnTop = false;

        # Based on http://stackoverflow.com/questions/195951/change-an-elements-class-with-javascript -- Begin
        hasClass = (element, className) ->
            regExp = new RegExp "(?:^|\\s)" + className + "(?!\\S)", "g"
            element.className.match(regExp) isnt null

        removeClass = (element, className) ->
            for name in className.split " "
                regExp = new RegExp "(?:^|\\s)" + name + "(?!\\S)", "g"
                element.className = element.className.replace regExp, ''

        addClass = (element, className) ->
            for name in className.split " "
                element.className += (" " + name) if not hasClass element, name

        replaceClass = (element, replaceClassName, byClassName) ->
            removeClass element, replaceClassName
            addClass element, byClassName
        # Based on http://stackoverflow.com/questions/195951/change-an-elements-class-with-javascript -- End

        getTableEventHandlers = (value, rowValues, colValues) ->
            return if not opts.table and not opts.table.eventHandlers
            eventHandlers = {}
            for own event, handler of opts.table.eventHandlers
                filters = {}
                filters[attr] = colValues[i] for own i, attr of colAttrs when colValues[i]?
                filters[attr] = rowValues[i] for own i, attr of rowAttrs when rowValues[i]?
                eventHandlers[event] = (e) -> handler(e, value, filters, pivotData)
            return eventHandlers

        createElement = (elementType, className, textContent, attributes, eventHandlers) ->
            e = document.createElement elementType
            e.className = className if className?
            e.textContent = textContent if textContent?
            e.setAttribute attr, val for own attr, val of attributes if attributes?
            e.addEventListener event, handler for own event, handler of eventHandlers if eventHandlers?
            return e

        setAttributes = (e, attrs) ->
            for own a, v of attrs
                e.setAttribute a, v 

        processKeys = (keysArr, className) ->
            lastIdx = keysArr[0].length-1
            tree = children: []
            row = 0
            keysArr.reduce(
                (val0, k0) => 
                    col = 0
                    k0.reduce(
                        (acc, curVal, curIdx, arr) => 
                            if not acc[curVal]
                                key = k0.slice 0, col+1
                                acc[curVal] =
                                    row: row
                                    col: col
                                    descendants: 0
                                    children: []
                                    text: curVal
                                    key: key 
                                    flatKey: key.join String.fromCharCode(0) 
                                    firstLeaf: null 
                                    leaves: 0
                                    parent: if col isnt 0 then acc else null
                                    th: createElement "th", className, curVal
                                    childrenSpan: 0
                                acc.children.push curVal
                            if col > 0 
                                acc.descendants++
                            col++
                            if curIdx == lastIdx
                                node = tree
                                for i in [0..lastIdx-1] when lastIdx > 0
                                    node[k0[i]].leaves++
                                    if not node[k0[i]].firstLeaf 
                                        node[k0[i]].firstLeaf = acc[curVal]
                                    node = node[k0[i]]
                                return tree
                            return acc[curVal]
                        tree)
                    row++
                    return tree
                tree)

        setColInitParams = (col) ->
            init = 
                colArrow: arrowExpanded
                colClass: classColExpanded
                colClickStatus: clickStatusExpanded
            if col >= colsCollapseAt
                init =
                    colArrow: arrowCollapsed
                    colClass: classColCollapsed
                    colClickStatus: clickStatusCollapsed
            if col >= colDisableFrom
                init =
                    colArrow: ""
            return init

        buildColHeaderHeader = (thead, colHeaderHeaders, rowAttrs, colAttrs, tr, col) ->
            colAttr = colAttrs[col]
            textContent = colAttr
            className = "pvtAxisLabel"
            init = setColInitParams col
            if col < colAttrs.length-1
                className += " " + init.colClass
                textContent = " " + init.colArrow + " " + colAttr if not (isColDisableExpandCollapse or isColDisable or col > colDisableAfter)
            th = createElement "th", className, textContent
            th.setAttribute "data-colAttr", colAttr
            tr.appendChild th
            colHeaderHeaders.push {
                tr: tr,
                th: th,
                clickStatus: init.colClickStatus,
                expandedCount: 0,
                nHeaders: 0}
            thead.appendChild tr

        buildColHeaderHeaders = (thead, colHeaderHeaders, rowAttrs, colAttrs) ->
            tr = createElement "tr"
            if rowAttrs.length != 0
                tr.appendChild createElement "th", null, null, {
                    colspan: rowAttrs.length,
                    rowspan: colAttrs.length}
            buildColHeaderHeader thead, colHeaderHeaders, rowAttrs, colAttrs, tr, 0
            for c in [1..colAttrs.length] when c < colAttrs.length
                tr = createElement("tr")
                buildColHeaderHeader thead, colHeaderHeaders, rowAttrs, colAttrs, tr, c

        buildColHeaderHeadersClickEvents = (colHeaderHeaders, colHeaderCols, colAttrs) ->
            n = colAttrs.length-1
            for i in [0..n] when i < n
                th = colHeaderHeaders[i].th
                colAttr = colAttrs[i]
                th.onclick = (event) ->
                    event = event || window.event
                    toggleColHeaderHeader colHeaderHeaders, colHeaderCols, colAttrs, event.target.getAttribute "data-colAttr"

        buildColHeader = (colHeaderHeaders, colHeaderCols, h, rowAttrs, colAttrs, node) ->
            # DF Recurse
            for chKey in h.children
                buildColHeader colHeaderHeaders, colHeaderCols, h[chKey], rowAttrs, colAttrs, node
            # Process
            init = setColInitParams h.col
            hh = colHeaderHeaders[h.col]
            ++hh.expandedCount if h.col <= colsCollapseAt
            ++hh.nHeaders

            firstChild = h[h.children[0]] if h.children.length isnt 0
            addClass h.th, "#{classColShow} col#{h.row} colcol#{h.col}"
            h.th.setAttribute "data-colnode", node.counter
            h.th.colSpan = h.childrenSpan if h.children.length isnt 0
            if h.children.length is 0 and rowAttrs.length isnt 0
                h.th.rowSpan = 2
            if h.leaves > 1 and not (isColDisable or h.col >= colDisableFrom)
                if not isColDisableExpandCollapse
                    h.th.textContent = "#{init.colArrow} #{h.text}"
                    h.th.onclick = (event) ->
                        event = event || window.event
                        toggleCol colHeaderHeaders, colHeaderCols, parseInt event.target.getAttribute "data-colnode"
                if h.children.length > 1
                    h.sTh = createElement "th", "pvtColLabelFiller pvtColSubtotal"
                    h.sTh.rowSpan = colAttrs.length-h.col
                    h.sTh.style.display = "none" if (isColHideOnExpand and h.col < colsCollapseAt) or h.col > colsCollapseAt
                    firstChild.tr.appendChild h.sTh
                    h.th.colSpan++

            h.parent?.childrenSpan += h.th.colSpan

            h.clickStatus = init.colClickStatus
            hh.tr.appendChild h.th
            h.tr = hh.tr
            colHeaderCols.push h
            node.counter++

        setRowInitParams = (col) ->
            init = 
                rowArrow: arrowExpanded
                rowClass: classRowExpanded
                rowClickStatus: clickStatusExpanded
            if col >= rowsCollapseAt
                init =
                    rowArrow: arrowCollapsed
                    rowClass: classRowCollapsed
                    rowClickStatus: clickStatusCollapsed
            if col >= rowDisableFrom
                init =
                    rowArrow: ""
            return init

        buildRowHeaderHeaders = (thead, rowHeaderHeaders, rowAttrs, colAttrs) ->
            tr = createElement "tr"
            rowHeaderHeaders.hh = []
            for own i, rowAttr of rowAttrs
                textContent = rowAttr
                className = "pvtAxisLabel"
                if i < rowAttrs.length-1
                    className += " expanded"
                    textContent = " " + arrowExpanded + " " + rowAttr if not (isRowDisableExpandCollapse or i >= rowDisableFrom or i >= rowsCollapseAt)
                th = createElement "th", className, textContent
                th.setAttribute "data-rowAttr", rowAttr
                tr.appendChild th
                rowHeaderHeaders.hh.push 
                    th: th,
                    clickStatus: if i < rowsCollapseAt then clickStatusExpanded else clickStatusCollapsed
                    expandedCount: 0,
                    nHeaders: 0
            if colAttrs.length != 0
                th = createElement "th"
                tr.appendChild th
            thead.appendChild tr
            rowHeaderHeaders.tr = tr

        buildRowHeaderHeadersClickEvents = (rowHeaderHeaders, rowHeaderRows, rowAttrs) ->
            n = rowAttrs.length-1
            for i in [0..n] when i < n
                th = rowHeaderHeaders.hh[i]
                rowAttr = rowAttrs[i]
                th.th.onclick = (event) ->
                    event = event || window.event
                    toggleRowHeaderHeader rowHeaderHeaders, rowHeaderRows, rowAttrs, event.target.getAttribute "data-rowAttr"

        buildRowTotalsHeader = (tr, rowAttrs, colAttrs) ->
            rowspan = 1
            if colAttrs.length != 0
                rowspan = colAttrs.length + (if rowAttrs.length == 0 then 0 else 1)
            th = createElement "th", "pvtTotalLabel rowTotal", opts.localeStrings.totals, {rowspan: rowspan}
            tr.appendChild th

        buildRowHeader = (tbody, rowHeaderHeaders, rowHeaderRows, h, rowAttrs, colAttrs, node) ->
            # DF Recurse
            for chKey in h.children
                buildRowHeader tbody, rowHeaderHeaders, rowHeaderRows, h[chKey], rowAttrs, colAttrs, node

            # Process
            hh = rowHeaderHeaders.hh[h.col]
            ++hh.expandedCount if h.col <= rowsCollapseAt
            ++hh.nHeaders

            init = setRowInitParams h.col
            firstChild = h[h.children[0]] if h.children.length isnt 0

            addClass h.th, "pvtRowSubtotal row#{h.row} rowcol#{h.col}"
            h.th.setAttribute "data-rownode", node.counter
            h.th.colSpan = 2 if h.col is rowAttrs.length-1 and colAttrs.length isnt 0
            h.th.rowSpan = h.childrenSpan if h.children.length isnt 0

            if (isDisplayOnTop and h.children.length is 1) or (not isDisplayOnTop and h.children.length isnt 0)
                h.tr = firstChild.tr
                h.tr.insertBefore h.th, firstChild.th
            else
                h.tr = createElement "tr", "pvtRowSubtotal row#{h.row}"
                h.tr.appendChild h.th

            if h.leaves > 1 and not (isRowDisable or h.col >= rowDisableFrom)
                if not isRowDisableExpandCollapse
                    addClass h.th, init.rowClass
                    h.th.textContent = "#{init.rowArrow} #{h.text}"
                    h.th.onclick = (event) ->
                        event = event || window.event
                        toggleRow rowHeaderHeaders, rowHeaderRows, parseInt event.target.getAttribute "data-rownode"

                if h.children.length > 1
                    h.sTh = createElement "th", "pvtRowLabelFiller pvtRowSubtotal row#{h.row} rowcol#{h.col} #{init.rowClass}"
                    h.sTh.colSpan = rowAttrs.length-(h.col+1) + if colAttrs.length != 0 then 1 else 0 
                    h.sTh.style.display = "none" if (isRowHideOnExpand and h.col < rowsCollapseAt) or h.col > rowsCollapseAt
                    h.th.rowSpan++

                    addClass h.tr, init.rowClass
                    if isDisplayOnTop
                        h.tr.appendChild h.sTh
                    else
                        h.sTr = createElement "tr", "pvtRowSubtotal row#{h.row} #{init.rowClass}"
                        h.sTr.appendChild h.sTh
                        tbody.appendChild h.sTr
                tbody.insertBefore h.tr, firstChild.tr
            else
                tbody.appendChild h.tr if h.children.length is 0

            h.parent?.childrenSpan += h.th.rowSpan

            h.clickStatus = init.rowClickStatus
            rowHeaderRows.push h
            node.counter++


        buildValues = (tbody, rowHeaderRows, colHeaderCols) ->
            for rowHeader in rowHeaderRows
                rowInit = setRowInitParams rowHeader.col
                flatRowKey = rowHeader.flatKey
                isRowSubtotal = rowHeader.descendants != 0;
                for colHeader in colHeaderCols
                    flatColKey = colHeader.flatKey
                    aggregator = tree[flatRowKey][flatColKey] ? {value: (-> null), format: -> ""}
                    val = aggregator.value()
                    isColSubtotal = colHeader.descendants != 0;
                    colInit = setColInitParams colHeader.col
                    style = "pvtVal"
                    style += " pvtColSubtotal #{colInit.colClass}" if isColSubtotal
                    style += " pvtRowSubtotal #{rowInit.rowClass}" if isRowSubtotal
                    style += if (isRowSubtotal and (rowHeader.col >= rowDisableFrom or (isRowHideOnExpand and rowHeader.col < rowsCollapseAt))) or (rowHeader.col > rowsCollapseAt) then " #{classRowHide}" else " #{classRowShow}"
                    style += if (isColSubtotal and (isColDisable or colHeader.col > colDisableAfter or (isColHideOnExpand and colHeader.col < colsCollapseAt))) or (colHeader.col > colsCollapseAt) then " #{classColHide}" else " #{classColShow}"
                    style += " row#{rowHeader.row}" +
                        " col#{colHeader.row}" +
                        " rowcol#{rowHeader.col}" +
                        " colcol#{colHeader.col}"
                    eventHandlers = getTableEventHandlers val, rowHeader.key, colHeader.key
                    td = createElement "td", style, aggregator.format(val),
                        "data-value": val,
                        "data-rownode": rowHeader.node,
                        "data-colnode": colHeader.node, eventHandlers
                    if not isDisplayOnTop
                        td.style.display = "none" if (rowHeader.col > rowsCollapseAt or colHeader.col > colsCollapseAt) or (isRowSubtotal and (rowHeader.col >= rowDisableFrom or (isRowHideOnExpand and rowHeader.col < rowsCollapseAt))) or (isColSubtotal and (isColDisable or colHeader.col > colDisableAfter or (isColHideOnExpand and colHeader.col < colsCollapseAt)))
                    
                    rowHeader.tr.appendChild td

                # buildRowTotal
                totalAggregator = rowTotals[flatRowKey]
                val = totalAggregator.value()
                style = "pvtTotal rowTotal #{rowInit.rowClass}"
                style += " pvtRowSubtotal " if isRowSubtotal 
                style += if isRowSubtotal and (rowHeader.col >= rowDisableFrom or not isDisplayOnTop or (isRowHideOnExpand and rowHeader.col < rowsCollapseAt)) then " #{classRowHide}" else " #{classRowShow}"
                style += " row#{rowHeader.row} rowcol#{rowHeader.col}"
                td = createElement "td", style, totalAggregator.format(val),
                    "data-value": val,
                    "data-row": "row#{rowHeader.row}",
                    "data-rowcol": "col#{rowHeader.col}",
                    "data-rownode": rowHeader.node, getTableEventHandlers val, rowHeader.key, []
                if not isDisplayOnTop
                    td.style.display = "none" if (rowHeader.col > rowsCollapseAt) or  (isRowSubtotal and (rowHeader.col >= rowDisableFrom or (isRowHideOnExpand and rowHeader.col < rowsCollapseAt)))
                rowHeader.tr.appendChild td

        buildColTotalsHeader = (rowAttrs, colAttrs) ->
            tr = createElement "tr"
            colspan = rowAttrs.length + (if colAttrs.length == 0 then 0 else 1)
            th = createElement "th", "pvtTotalLabel colTotal", opts.localeStrings.totals, {colspan: colspan}
            tr.appendChild th
            return tr

        buildColTotals = (tr, colHeaderCols) ->
            for h in colHeaderCols when h.children.length isnt 1
                isColSubtotal = h.descendants != 0
                totalAggregator = colTotals[h.flatKey]
                val = totalAggregator.value()
                colInit = setColInitParams h.col
                clsNames = "pvtVal pvtTotal colTotal #{colInit.colClass} col#{h.row} colcol#{h.col}"
                clsNames += " pvtColSubtotal" if isColSubtotal
                td = createElement "td", clsNames, totalAggregator.format(val),
                    "data-value": val
                    "data-for": "col#{h.col}"
                    "data-colnode": "#{h.node}", getTableEventHandlers val, [], h.key
                td.style.display = "none" if (h.col > colsCollapseAt) or (isColSubtotal and (isColDisable or h.col > colDisableAfter or (isColHideOnExpand and h.col < colsCollapseAt)))
                tr.appendChild td

        buildGrandTotal = (result, tr) ->
            totalAggregator = allTotal
            val = totalAggregator.value()
            td = createElement "td", "pvtGrandTotal", totalAggregator.format(val),
                {"data-value": val},
                getTableEventHandlers val, [], []
            tr.appendChild td
            result.appendChild tr


        hideDescendantCol = (d) ->
            $(d.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{d.node}\"], th[data-colnode=\"#{d.node}\"]" 
                .removeClass classColShow 
                .addClass classColHide 
                .css 'display', "none" 

        collapseShowColSubtotal = (h) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass "#{classColExpanded} #{classColHide}"
                .addClass "#{classColCollapsed} #{classColShow}"
                .not ".pvtRowSubtotal.#{classRowHide}"
                .css 'display', "" 
            h.th.textContent = " " + arrowCollapsed + " " + h.th.getAttribute "data-colheader"
            h.th.colSpan = 1

        collapseCol = (colHeaderHeaders, colHeaderCols, c) ->
            return if isColDisable or isColDisableExpandCollapse or not colHeaderCols[c]

            h = colHeaderCols[c]
            return if h.col > colDisableAfter
            return if h.clickStatus is clickStatusCollapsed

            isColSubtotal = h.descendants != 0
            colspan = h.th.colSpan 
            for i in [1..h.descendants] when h.descendants != 0
                d = colHeaderCols[c-i]
                hideDescendantCol d
            if isColSubtotal 
                collapseShowColSubtotal h
                --colspan
            p = h.parent
            while p isnt null
                p.th.colSpan -= colspan
                p = p.parent
            h.clickStatus = clickStatusCollapsed
            colHeaderHeader = colHeaderHeaders[h.col]
            colHeaderHeader.expandedCount--
            if colHeaderHeader.expandedCount == 0
                for i in [h.col..colHeaderHeaders.length-2] when i <= colDisableAfter
                    colHeaderHeader = colHeaderHeaders[i]
                    replaceClass colHeaderHeader.th, classExpanded, classCollapsed
                    colHeaderHeader.th.textContent = " " + arrowCollapsed + " " + colHeaderHeader.th.getAttribute "data-colAttr"
                    colHeaderHeader.clickStatus = clickStatusCollapsed

        showChildCol = (ch) ->
            $(ch.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{ch.node}\"], th[data-colnode=\"#{ch.node}\"]" 
                .removeClass classColHide
                .addClass classColShow
                .not ".pvtRowSubtotal.#{classRowHide}"
                .css 'display', "" 

        expandHideColSubtotal = (h) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass "#{classColCollapsed} #{classColShow}" 
                .addClass "#{classColExpanded} #{classColHide}" 
                .css 'display', "none" 
            h.th.style.display = ""

        expandShowColSubtotal = (h) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass "#{classColCollapsed} #{classColHide}"
                .addClass "#{classColExpanded} #{classColShow}"
                .not ".pvtRowSubtotal.#{classRowHide}"
                .css 'display', "" 
            h.th.style.display = ""
            ++h.th.colSpan
            h.sTh.style.display = "" if h.sTh?

        expandChildCol = (ch) ->
            if ch.descendants != 0 and hasClass(ch.th, classColExpanded) and (isColDisable or ch.col > colDisableAfter or isColHideOnExpand)
                ch.th.style.display = ""
            else
                showChildCol ch
            expandChildCol gch for gch in ch.children if ch.clickStatus isnt clickStatusCollapsed

        expandCol = (colHeaderHeaders, colHeaderCols, c) ->
            return if isColDisable
            return if isColDisableExpandCollapse
            return if not colHeaderCols[c]

            h = colHeaderCols[c]
            return if h.col > colDisableAfter
            return if h.clickStatus is clickStatusExpanded

            isColSubtotal = h.descendants != 0
            colspan = 0
            for ch in h.children
                expandChildCol ch
                colspan += ch.th.colSpan
            h.th.colSpan = colspan
            if isColSubtotal
                replaceClass h.th, classColCollapsed, classColExpanded
                h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute "data-colHeader"
                if isColHideOnExpand
                    expandHideColSubtotal h
                    --colspan
                else
                    expandShowColSubtotal h
            p = h.parent
            while p
                p.th.colSpan += colspan
                p = p.parent
            h.clickStatus = clickStatusExpanded
            hh = colHeaderHeaders[h.col]
            ++hh.expandedCount
            if hh.expandedCount is hh.nHeaders
                replaceClass hh.th, classCollapsed, classExpanded
                hh.th.textContent = " " + arrowExpanded + " " + hh.th.getAttribute "data-colAttr"
                hh.clickStatus = clickStatusExpanded

        hideDescendantRow = (d) ->
            d.tr.style.display = "none" if isDisplayOnTop
            cells = d.tr.getElementsByTagName "td"
            replaceClass cell, classRowShow, classRowHide for cell in cells
            if not isDisplayOnTop
                cell.style.display = "none" for cell in cells
                d.sTh.style.display = "none" if d.sTh
                d.th.style.display = "none"

        collapseShowRowSubtotal = (h) ->
            cells = h.tr.getElementsByTagName "td" 
            for cell in cells
                removeClass cell, "#{classRowExpanded} #{classRowHide}"
                addClass cell, "#{classRowCollapsed} #{classRowShow}"
                cell.style.display = "" if not hasClass cell, classColHide
            h.sTh.textContent = " " + arrowCollapsed + " " + h.sTh.getAttribute "data-rowHeader"
            replaceClass h.sTh, classRowExpanded, classRowCollapsed
            replaceClass h.tr, classRowExpanded, classRowCollapsed
            h.tr.style.display = ""

        collapseRow = (rowHeaderHeaders, rowHeaderRows, r) ->
            h = rowHeaderRows[r]
            return if not h or h.clickStatus is clickStatusCollapsed or h.col >= rowDisableFrom or isRowDisableExpandCollapse 

            rowSpan = h.th.rowSpan
            isRowSubtotal = h.descendants != 0
            for i in [1..h.descendants] when h.descendants != 0
                d = rowHeaderRows[r-i]
                hideDescendantRow d
            h.th.style.display = "none" if not isDisplayOnTop
            collapseShowRowSubtotal h if isRowSubtotal
            if isDisplayOnTop
                p = h.parent
                while p
                    p.th.rowSpan -= rowSpan
                    p = p.parent
            h.clickStatus = clickStatusCollapsed

            hh = rowHeaderHeaders.hh[h.col]
            hh.expandedCount--

            return if hh.expandedCount != 0

            for j in [h.col..rowHeaderHeaders.hh.length-2] when j < rowDisableFrom
                hh = rowHeaderHeaders.hh[j]
                replaceClass hh.th, classExpanded, classCollapsed
                hh.th.textContent = " " + arrowCollapsed + " " + hh.th.getAttribute "data-rowAttr"
                hh.clickStatus = clickStatusCollapsed

        showChildRow = (h) ->
            cells = h.tr.getElementsByTagName "td" 
            for cell in cells
                replaceClass cell, classRowHide, classRowShow
            if not isDisplayOnTop
                cell.style.display = "" for cell in cells when not hasClass cell, classColHide
                h.th.style.display = "" if h.descendants == 0 or h.clickStatus isnt clickStatusCollapsed
                h.sTh.style.display = "" if h.sTh
            h.tr.style.display = ""

        expandShowRowSubtotal = (h) ->
            cells = h.tr.getElementsByTagName "td"
            for cell in cells
                removeClass cell, "#{classRowCollapsed} #{classRowHide}"
                addClass cell, "#{classRowExpanded} #{classRowShow}" 
                cell.style.display = "" if not hasClass cell, classColHide
            h.sTh.textContent = " " + arrowExpanded + " " + h.sTh.getAttribute "data-rowHeader"
            h.sTh.style.display = ""
            replaceClass h.sTh, classRowCollapsed, classRowExpanded
            h.th.style.display = ""
            replaceClass h.th, classRowCollapsed, classRowExpanded
            replaceClass h.tr, classRowCollapsed, classRowExpanded
            h.tr.style.display = ""

        expandHideRowSubtotal = (h) ->
            cells = h.tr.getElementsByTagName "td"
            for cell in cells
                removeClass cell, "#{classRowCollapsed} #{classRowShow}"
                addClass cell, "#{classRowExpanded} #{classRowHide}"
            h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute "data-rowHeader"
            h.th.style.display = ""
            replaceClass h.tr, classRowCollapsed, classRowExpanded
            h.tr.style.display = "none"

        expandChildRow = (ch) ->
            nShown = 0
            if ch.descendants != 0
                showChildRow ch
                nShown++
                nShown += expandChildRow gch for gch in ch.children when ch.clickStatus isnt clickStatusCollapsed
            else
                showChildRow ch
                nShown++
            return nShown

        expandRow = (rowHeaderHeaders, rowHeaderRows, r) ->
            h = rowHeaderRows[r]
            return if not h or h.clickStatus is clickStatusExpanded or isRowDisableExpandCollapse or h.col >= rowDisableFrom

            isRowSubtotal = h.descendants != 0
            nShown = 0
            for ch in h.children
                nShown +=  expandChildRow ch, 0
            if isRowSubtotal
                if isRowHideOnExpand
                    expandHideRowSubtotal h
                else
                    expandShowRowSubtotal h
            if isDisplayOnTop
                h.th.rowSpan = nShown
                p = h.parent
                while p
                    p.th.rowSpan += nShown
                    p = p.parent
            h.clickStatus = clickStatusExpanded
            hh = rowHeaderHeaders.hh[h.col]
            ++hh.expandedCount
            if hh.expandedCount == hh.nHeaders
                replaceClass hh.th, classCollapsed, classExpanded
                hh.th.textContent = " " + arrowExpanded + " " + hh.th.getAttribute "data-rowAttr"
                hh.clickStatus = clickStatusExpanded

        toggleCol = (colHeaderHeaders, colHeaderCols, c) ->
            return if not colHeaderCols[c]?

            h = colHeaderCols[c]
            if h.clickStatus is clickStatusCollapsed
                expandCol(colHeaderHeaders, colHeaderCols, c)
            else
                collapseCol(colHeaderHeaders, colHeaderCols, c)
            h.th.scrollIntoView

        toggleRow = (rowHeaderHeaders, rowHeaderRows, r) ->
            h = rowHeaderRows[r]
            return if not h

            if h.clickStatus is clickStatusCollapsed
                expandRow(rowHeaderHeaders, rowHeaderRows, r)
            else
                collapseRow(rowHeaderHeaders, rowHeaderRows, r)

        collapseColsAt = (colHeaderHeaders, colHeaderCols, colAttrs, colAttr) ->
            return if isColDisable
            if typeof colAttr is 'string'
                idx = colAttrs.indexOf colAttr
            else
                idx = colAttr
            return if idx < 0 or idx == colAttrs.length-1
            i = idx
            nAttrs = colAttrs.length-1
            while i < nAttrs and i <= colDisableAfter
                hh = colHeaderHeaders[i]
                replaceClass hh.th, classExpanded, classCollapsed
                hh.th.textContent = " " + arrowCollapsed + " " + colAttrs[i]
                hh.clickStatus = clickStatusCollapsed
                ++i
            i = 0
            nCols = colHeaderCols.length
            while i < nCols
                h = colHeaderCols[i]
                if h.col is idx and h.clickStatus isnt clickStatusCollapsed and h.th.style.display isnt "none"
                    collapseCol colHeaderHeaders, colHeaderCols, parseInt h.th.getAttribute("data-colnode")
                ++i

        expandColsAt = (colHeaderHeaders, colHeaderCols, colAttrs, colAttr) ->
            return if isColDisable
            if typeof colAttr is 'string'
                idx = colAttrs.indexOf colAttr
            else
                idx = colAttr
            return if idx < 0 or idx == colAttrs.length-1
            for i in [0..idx]
                if i <= colDisableAfter
                    hh = colHeaderHeaders[i]
                    replaceClass hh.th, classCollapsed, classExpanded
                    hh.th.textContent = " " + arrowExpanded + " " + colAttrs[i]
                    hh.clickStatus = clickStatusExpanded
                j = 0
                nCols = colHeaderCols.length
                while j < nCols
                    h = colHeaderCols[j]
                    expandCol colHeaderHeaders, colHeaderCols, j if h.col == i
                    ++j
            ++idx
            while idx < colAttrs.length-1 and idx <= colDisableAfter
                colHeaderHeader = colHeaderHeaders[idx]
                if colHeaderHeader.expandedCount == 0
                    replaceClass colHeaderHeader.th, classExpanded, classCollapsed
                    colHeaderHeader.th.textContent = " " + arrowCollapsed + " " + colAttrs[idx]
                    colHeaderHeader.clickStatus = clickStatusCollapsed
                else if colHeaderHeader.expandedCount == colHeaderHeader.nHeaders
                    replaceClass colHeaderHeader.th, classCollapsed, classExpanded
                    colHeaderHeader.th.textContent = " " + arrowExpanded + " " + colAttrs[idx]
                    colHeaderHeader.clickStatus = clickStatusExpanded
                ++idx

        collapseRowsAt = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            return if isRowDisable
            if typeof rowAttr is 'string'
                idx = rowAttrs.indexOf rowAttr
            else
                idx = rowAttr

            return if idx < 0 or idx == rowAttrs.length-1

            i = idx
            nAttrs = rowAttrs.length-1
            while i < nAttrs and i < rowDisableFrom
                h = rowHeaderHeaders.hh[i]
                replaceClass h.th, classExpanded, classCollapsed
                h.th.textContent = " " + arrowCollapsed + " " + rowAttrs[i]
                h.clickStatus = clickStatusCollapsed
                ++i
            j = 0
            nRows = rowHeaderRows.length
            while j < nRows
                h = rowHeaderRows[j]
                if h.col is idx and h.clickStatus isnt clickStatusCollapsed and h.tr.style.display isnt "none"
                    collapseRow rowHeaderHeaders, rowHeaderRows, j
                ++j

        expandRowsAt = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            return if isRowDisable
            if typeof rowAttr is 'string'
                idx = rowAttrs.indexOf rowAttr
            else
                idx = rowAttr

            return if idx < 0 or idx == rowAttrs.length-1

            for i in [0..idx]
                if i < rowDisableFrom
                    hh = rowHeaderHeaders.hh[i]
                    replaceClass hh.th, classCollapsed, classExpanded
                    hh.th.textContent = " " + arrowExpanded + " " + rowAttrs[i]
                    hh.clickStatus = clickStatusExpanded
                j = 0
                nRows = rowHeaderRows.length
                while j < nRows
                    h = rowHeaderRows[j]
                    expandRow rowHeaderHeaders, rowHeaderRows, j if h.col == i
                    ++j
            ++idx
            while idx < rowAttrs.length-1 and idx < rowDisableFrom
                rowHeaderHeader = rowHeaderHeaders.hh[idx]
                if rowHeaderHeader.expandedCount == 0
                    replaceClass rowHeaderHeader.th, classExpanded, classCollapsed
                    rowHeaderHeader.th.textContent = " " + arrowCollapsed + " " + rowAttrs[idx]
                    rowHeaderHeader.clickStatus = clickStatusCollapsed
                else if rowHeaderHeader.expandedCount == rowHeaderHeader.nHeaders
                    replaceClass rowHeaderHeader.th, classCollapsed, classExpanded
                    rowHeaderHeader.th.textContent = " " + arrowExpanded + " " + rowAttrs[idx]
                    rowHeaderHeader.clickStatus = clickStatusExpanded
                ++idx

        toggleColHeaderHeader = (colHeaderHeaders, colHeaderCols, colAttrs, colAttr) ->
            return if isColDisable
            return if isColDisableExpandCollapse

            idx = colAttrs.indexOf colAttr
            h = colHeaderHeaders[idx]
            return if h.col > colDisableAfter
            if h.clickStatus is clickStatusCollapsed
                expandColsAt colHeaderHeaders, colHeaderCols, colAttrs, colAttr
            else
                collapseColsAt colHeaderHeaders, colHeaderCols, colAttrs, colAttr


        toggleRowHeaderHeader = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            return if isRowDisableExpandCollapse

            idx = rowAttrs.indexOf rowAttr
            th = rowHeaderHeaders.hh[idx]
            return if th.col >= rowDisableFrom
            if th.clickStatus is clickStatusCollapsed
                expandRowsAt rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr
            else
                collapseRowsAt rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr

        main = (rowAttrs, rowKeys, colAttrs, colKeys) ->
            rowHeaders = []
            colHeaders = []
            rowHeaderHeaders = {}
            rowHeaderRows = []
            colHeaderHeaders = []
            colHeaderCols = []

            rowHeaders = processKeys rowKeys, "pvtRowLabel" if rowAttrs.length > 0 and rowKeys.length > 0
            colHeaders = processKeys colKeys, "pvtColLabel" if colAttrs.length > 0 and colKeys.length > 0

            result = createElement "table", "pvtTable", null, {style: "display: none;"}

            thead = createElement "thead"
            result.appendChild thead

            if colAttrs.length > 0
                buildColHeaderHeaders thead, colHeaderHeaders, rowAttrs, colAttrs
                node = counter: 0
                buildColHeader colHeaderHeaders, colHeaderCols, colHeaders[chKey], rowAttrs, colAttrs, node for chKey in colHeaders.children
                buildColHeaderHeadersClickEvents colHeaderHeaders, colHeaderCols, colAttrs

            if rowAttrs.length > 0
                buildRowHeaderHeaders thead, rowHeaderHeaders, rowAttrs, colAttrs
                buildRowTotalsHeader rowHeaderHeaders.tr, rowAttrs, colAttrs if colAttrs.length == 0

            if colAttrs.length > 0
                buildRowTotalsHeader colHeaderHeaders[0].tr, rowAttrs, colAttrs

            tbody = createElement "tbody"
            result.appendChild tbody
            node = counter: 0
            buildRowHeader tbody, rowHeaderHeaders, rowHeaderRows, rowHeaders[chKey], rowAttrs, colAttrs, node for chKey in rowHeaders.children if rowAttrs.length > 0
            buildRowHeaderHeadersClickEvents rowHeaderHeaders, rowHeaderRows, rowAttrs
            # buildValues tbody, rowHeaderRows, colHeaderCols
            tr = buildColTotalsHeader rowAttrs, colAttrs
            buildColTotals tr, colHeaderCols if colAttrs.length > 0
            buildGrandTotal tbody, tr

            result.setAttribute "data-numrows", rowKeys.length
            result.setAttribute "data-numcols", colKeys.length
            result.style.display = ""

            return result

        return main rowAttrs, rowKeys, colAttrs, colKeys

    $.pivotUtilities.subtotal_renderers =
        "Table With Subtotal":  (pvtData, opts) -> SubtotalRenderer pvtData, opts
        "Table With Subtotal Bar Chart":   (pvtData, opts) -> $(SubtotalRenderer pvtData, opts).barchart()
        "Table With Subtotal Heatmap":   (pvtData, opts) -> $(SubtotalRenderer pvtData, opts).heatmap "heatmap", opts
        "Table With Subtotal Row Heatmap":   (pvtData, opts) -> $(SubtotalRenderer pvtData, opts).heatmap "rowheatmap", opts
        "Table With Subtotal Col Heatmap":  (pvtData, opts) -> $(SubtotalRenderer pvtData, opts).heatmap "colheatmap", opts

    #
    # 
    # Aggregators
    # 
    #

    usFmtPct = $.pivotUtilities.numberFormat digitsAfterDecimal:1, scaler: 100, suffix: "%"
    aggregatorTemplates = $.pivotUtilities.aggregatorTemplates;

    subtotalAggregatorTemplates =
        fractionOf: (wrapped, type="row", formatter=usFmtPct) -> (x...) -> (data, rowKey, colKey) ->
            rowKey = [] if typeof rowKey is "undefined"
            colKey = [] if typeof colKey is "undefined"
            selector: {row: [rowKey.slice(0, -1),[]], col: [[], colKey.slice(0, -1)]}[type]
            inner: wrapped(x...)(data, rowKey, colKey)
            push: (record) -> @inner.push record
            format: formatter
            value: -> @inner.value() / data.getAggregator(@selector...).inner.value()
            numInputs: wrapped(x...)().numInputs

    $.pivotUtilities.subtotalAggregatorTemplates = subtotalAggregatorTemplates

    $.pivotUtilities.subtotal_aggregators = do (tpl = aggregatorTemplates, sTpl = subtotalAggregatorTemplates) ->
        "Sum As Fraction Of Parent Row":        sTpl.fractionOf(tpl.sum(), "row", usFmtPct)
        "Sum As Fraction Of Parent Column":     sTpl.fractionOf(tpl.sum(), "col", usFmtPct)
        "Count As Fraction Of Parent Row":      sTpl.fractionOf(tpl.count(), "row", usFmtPct)
        "Count As Fraction Of Parent Column":   sTpl.fractionOf(tpl.count(), "col", usFmtPct)

