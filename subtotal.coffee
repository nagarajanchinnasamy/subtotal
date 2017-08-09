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
        isRowHideOnExpand = opts.rowSubtotalDisplay?.hideOnExpand
        isRowDisableExpandCollapse = opts.rowSubtotalDisplay?.disableExpandCollapse
        rowDisableAfter = opts.rowSubtotalDisplay?.disableAfter ?= 9999
        isColDisable = opts.colSubtotalDisplay?.disableSubtotal
        isColHideOnExpand = opts.colSubtotalDisplay?.hideOnExpand
        isColDisableExpandCollapse = opts.colSubtotalDisplay?.disableExpandCollapse
        colDisableAfter = opts.colSubtotalDisplay?.disableAfter ?= 9999
        arrowCollapsed = opts.arrowCollapsed ?= "\u25B6"
        arrowExpanded = opts.arrowExpanded ?= "\u25E2"

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
            headers = []
            lastRow = keysArr.length - 1
            lastCol = keysArr[0].length - 1
            rMark = []
            th = createElement "th", className, keysArr[0][0]
            key = []
            key.push keysArr[0][0]
            nodePos = 0
            node = {
                node: nodePos,
                row: 0,
                col: 0,
                th: th,
                parent: null,
                children: [],
                descendants: lastCol,
                leaves: 1,
                key: key,
                flatKey: key.join String.fromCharCode(0)}
            headers.push node
            rMark[0] = node
            c = 1
            while c <= lastCol
                th = createElement "th", className, keysArr[0][c]
                key = key.slice()
                key.push keysArr[0][c]
                ++nodePos
                node =  {
                    node: nodePos,
                    row: 0,
                    col: c,
                    th: th,
                    parent: rMark[c-1],
                    children: [],
                    descendants: lastCol-c,
                    leaves: 1,
                    key: key,
                    flatKey: key.join String.fromCharCode(0)}
                rMark[c] = node
                rMark[c-1].children.push node
                ++c
            rMark[lastCol].leaves = 0
            r = 1
            while r <= lastRow
                repeats = true
                key = []
                c = 0
                while c <= lastCol
                    key = key.slice()
                    key.push keysArr[r][c]
                    if ((keysArr[r][c] is keysArr[rMark[c].row][c]) and (c isnt lastCol)  and (repeats))
                        repeats = true
                        ++c
                        continue
                    th = createElement "th", className, keysArr[r][c]
                    ++nodePos
                    node = {
                        node: nodePos,
                        row: r,
                        col: c,
                        th: th,
                        parent: null,
                        children: [],
                        descendants: 0,
                        leaves: 0,
                        key: key,
                        flatKey: key.join String.fromCharCode(0)}
                    if c is 0
                        headers.push node
                    else
                        node.parent = rMark[c-1]
                        rMark[c-1].children.push node
                        x = 0
                        while x <= c-1
                            ++rMark[x].descendants
                            ++x
                    rMark[c] = node
                    repeats = false
                    ++c
                ++rMark[c].leaves for c in [0..lastCol]
                rMark[lastCol].leaves = 0
                ++r
            return headers

        buildColHeaderHeader = (thead, colHeaderHeaders, rowAttrs, colAttrs, tr, col) ->
            colAttr = colAttrs[col]
            textContent = colAttr
            className = "pvtAxisLabel"
            if col < colAttrs.length-1
                className += " expanded"
                textContent = " " + arrowExpanded + " " + colAttr if not (isColDisableExpandCollapse or isColDisable or col > colDisableAfter)
            th = createElement "th", className, textContent
            th.setAttribute "data-colAttr", colAttr
            tr.appendChild th
            colHeaderHeaders.push {
                tr: tr,
                th: th,
                clickStatus: clickStatusExpanded,
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

        buildColHeaders = (colHeaderHeaders, colHeaderCols, colHeader, rowAttrs, colAttrs) ->
            # DF Recurse
            for h in colHeader.children
                buildColHeaders colHeaderHeaders, colHeaderCols, h, rowAttrs, colAttrs
            # Process
            #
            # NOTE:
            # 
            # We replace colHeader.node with colHeaderCols.length.
            # colHeader.node is not useful as columns are positioned depth-first 
            #
            isColSubtotal = colHeader.children.length != 0
            colHeader.node = colHeaderCols.length
            hh = colHeaderHeaders[colHeader.col]
            ++hh.expandedCount
            ++hh.nHeaders
            tr = hh.tr
            th = colHeader.th
            addClass th, "col#{colHeader.row} colcol#{colHeader.col} #{classColShow}"
            if isColHideOnExpand or isColDisable or (isColSubtotal and colHeader.col > colDisableAfter)
                colspan = colHeader.leaves
            else if isColSubtotal and colHeader.col <= colDisableAfter
                colspan = colHeader.leaves + 1
            else
                colspan = colHeader.descendants+1
            setAttributes th,
                "rowspan": if colHeader.col == colAttrs.length-1 and rowAttrs.length != 0 then 2 else 1
                "colspan": colspan, 
                "data-colnode": colHeader.node,
                "data-colHeader": th.textContent
            if isColSubtotal
                addClass th, classColExpanded
                th.textContent = " #{arrowExpanded} #{th.textContent}" if not
                    (isColDisableExpandCollapse or isColDisable or colHeader.col > colDisableAfter)
                th.onclick = (event) ->
                    event = event || window.event
                    toggleCol colHeaderHeaders, colHeaderCols, parseInt event.target.getAttribute "data-colnode"
                rowspan = colAttrs.length-(colHeader.col+1) + if rowAttrs.length != 0 then 1 else 0
                style = "pvtColLabel pvtColSubtotal #{classColExpanded}"
                style += " col#{colHeader.row} colcol#{colHeader.col}"
                style += " #{classColHide}" if isColHideOnExpand or isColDisable or colHeader.col > colDisableAfter
                sTh = createElement "th", style, '', {"rowspan": rowspan, "data-colnode": colHeader.node}
                addClass sTh, if isColHideOnExpand or isColDisable then " #{classColHide}" else " #{classColShow}"
                sTh.style.display = "none" if isColHideOnExpand or isColDisable or colHeader.col > colDisableAfter
                colHeader.children[0].tr.appendChild sTh
                colHeader.sTh = sTh
            colHeader.clickStatus = clickStatusExpanded
            tr.appendChild(th)
            colHeader.tr = tr
            colHeaderCols.push colHeader

        buildRowHeaderHeaders = (thead, rowHeaderHeaders, rowAttrs, colAttrs) ->
            tr = createElement "tr"
            rowHeaderHeaders.hh = []
            for own i, rowAttr of rowAttrs
                textContent = rowAttr
                className = "pvtAxisLabel"
                if i < rowAttrs.length-1
                    className += " expanded"
                    textContent = " " + arrowExpanded + " " + rowAttr if not (isRowDisableExpandCollapse or isRowDisable or i > rowDisableAfter)
                th = createElement "th", className, textContent
                th.setAttribute "data-rowAttr", rowAttr
                tr.appendChild th
                rowHeaderHeaders.hh.push 
                    th: th,
                    clickStatus: clickStatusExpanded,
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

        buildRowHeaders = (tbody, rowHeaderHeaders, rowHeaderRows, rowHeader, rowAttrs, colAttrs) ->
            hh = rowHeaderHeaders.hh[rowHeader.col]
            ++hh.expandedCount
            ++hh.nHeaders
            tr = createElement "tr", "pvtRowSubtotal row#{rowHeader.row}", "", "data-rownode": rowHeader.node 
            th = rowHeader.th
            isRowSubtotal = rowHeader.children.length != 0;
            addClass th, "row#{rowHeader.row} rowcol#{rowHeader.col} #{classRowShow}"
            setAttributes th,
                "data-rowHeader": th.textContent,
                "data-rownode": rowHeader.node,
                "rowspan": rowHeader.descendants+1,
                "colspan": if rowHeader.col == rowAttrs.length-1 and colAttrs.length != 0 then 2 else 1
            tr.appendChild th
            if isRowSubtotal
                addClass tr, classRowExpanded
                addClass th, classRowExpanded
                th.textContent = " " + arrowExpanded + " " + th.textContent if not (isRowDisableExpandCollapse or isRowDisable or rowHeader.col > rowDisableAfter)
                th.onclick = (event) ->
                    event = event || window.event
                    toggleRow rowHeaderHeaders, rowHeaderRows, parseInt event.target.getAttribute "data-rownode"
                # Filler th
                colspan = rowAttrs.length-(rowHeader.col+1) + if colAttrs.length != 0 then 1 else 0
                style = "pvtRowLabel pvtRowSubtotal #{classRowExpanded}"
                style += " row#{rowHeader.row} rowcol#{rowHeader.col}"
                style += if isRowHideOnExpand or isRowDisable or rowHeader.col > rowDisableAfter then " #{classRowHide}" else " #{classRowShow}"
                th = createElement "th", style, '', {"colspan": colspan, "data-rownode": rowHeader.node}
                th.style.display = "none" if isRowHideOnExpand or isRowDisable or rowHeader.col > rowDisableAfter
                tr.appendChild th
            rowHeader.clickStatus = clickStatusExpanded
            rowHeader.tr = tr
            rowHeaderRows.push rowHeader
            tbody.appendChild tr
            for h in rowHeader.children
                buildRowHeaders tbody, rowHeaderHeaders, rowHeaderRows, h, rowAttrs, colAttrs

        buildValues = (rowHeaderRows, colHeaderCols) ->
            for rowHeader in rowHeaderRows
                tr = rowHeader.tr
                flatRowKey = rowHeader.flatKey
                isRowSubtotal = rowHeader.children.length != 0;
                for colHeader in colHeaderCols
                    flatColKey = colHeader.flatKey
                    aggregator = tree[flatRowKey][flatColKey] ? {value: (-> null), format: -> ""}
                    val = aggregator.value()
                    isColSubtotal = colHeader.children.length != 0;
                    style = "pvtVal"
                    style += " pvtColSubtotal #{classColExpanded}" if isColSubtotal
                    style += " pvtRowSubtotal #{classRowExpanded}" if isRowSubtotal
                    style += if isRowSubtotal and (isRowHideOnExpand or isRowDisable or rowHeader.col > rowDisableAfter) then " #{classRowHide}" else " #{classRowShow}"
                    style += if isColSubtotal and (isColHideOnExpand  or isColDisable or colHeader.col > colDisableAfter) then " #{classColHide}" else " #{classColShow}"
                    style += " row#{rowHeader.row}" +
                        " col#{colHeader.row}" +
                        " rowcol#{rowHeader.col}" +
                        " colcol#{colHeader.col}"
                    eventHandlers = getTableEventHandlers val, rowHeader.key, colHeader.key
                    td = createElement "td", style, aggregator.format(val),
                        "data-value": val,
                        "data-rownode": rowHeader.node,
                        "data-colnode": colHeader.node, eventHandlers
                    td.style.display = "none" if (isRowSubtotal and (isRowHideOnExpand or isRowDisable or rowHeader.col > rowDisableAfter)) or (isColSubtotal and (isColHideOnExpand or isColDisable or colHeader.col > colDisableAfter))
                    tr.appendChild td
                # buildRowTotal
                totalAggregator = rowTotals[flatRowKey]
                val = totalAggregator.value()
                style = "pvtTotal rowTotal"
                style += " pvtRowSubtotal" if isRowSubtotal 
                style += if isRowSubtotal and (isRowHideOnExpand or isRowDisable or rowHeader.col > rowDisableAfter) then " #{classRowHide}" else " #{classRowShow}"
                style += " row#{rowHeader.row} rowcol#{rowHeader.col}"
                td = createElement "td", style, totalAggregator.format(val),
                    "data-value": val,
                    "data-row": "row#{rowHeader.row}",
                    "data-rowcol": "col#{rowHeader.col}",
                    "data-rownode": rowHeader.node, getTableEventHandlers val, rowHeader.key, []
                td.style.display = "none" if isRowSubtotal and (isRowHideOnExpand or isRowDisable or rowHeader.col > rowDisableAfter)
                tr.appendChild td

        buildColTotalsHeader = (rowAttrs, colAttrs) ->
            tr = createElement "tr"
            colspan = rowAttrs.length + (if colAttrs.length == 0 then 0 else 1)
            th = createElement "th", "pvtTotalLabel colTotal", opts.localeStrings.totals, {colspan: colspan}
            tr.appendChild th
            return tr

        buildColTotals = (tr, colHeaderCols) ->
            for h in colHeaderCols
                isColSubtotal = h.children.length != 0
                totalAggregator = colTotals[h.flatKey]
                val = totalAggregator.value()
                style = "pvtVal pvtTotal colTotal"
                style += " pvtColSubtotal" if isColSubtotal
                style += " #{classColExpanded}"
                style += " col#{h.row} colcol#{h.col}"
                td = createElement "td", style, totalAggregator.format(val),
                    "data-value": val
                    "data-for": "col#{h.col}"
                    "data-colnode": "#{h.node}", getTableEventHandlers val, [], h.key
                td.style.display = "none" if isColSubtotal and (isColHideOnExpand or isColDisable or h.col > colDisableAfter)
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
            return if isColDisable
            return if isColDisableExpandCollapse
            return if not colHeaderCols[c]

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
            if ch.descendants != 0 and hasClass(ch.th, classColExpanded) and (isColHideOnExpand or isColDisable or ch.col > colDisableAfter)
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

        collapseHideDescendantRow = (h) ->
            h.tr.style.display = "none"
            for tagName in ["td", "th"]
                cells = h.tr.getElementsByTagName tagName 
                for cell in cells
                    replaceClass cell, classRowShow, classRowHide
                    cell.style.display = "none"

        collapseShowRowSubtotal = (h) ->
            for tagName in ["td", "th"]
                cells = h.tr.getElementsByTagName tagName 
                for cell in cells
                    removeClass cell, "#{classRowExpanded} #{classRowHide}"
                    addClass cell, "#{classRowCollapsed} #{classRowShow}"
                    cell.style.display = "" if not hasClass cell, classColHide
            h.th.rowSpan = 1
            h.th.textContent = " " + arrowCollapsed + " " + h.th.getAttribute "data-rowHeader"
            replaceClass h.tr, classRowExpanded, classRowCollapsed

        collapseRow = (rowHeaderHeaders, rowHeaderRows, r) ->
            return if isRowDisable
            return if isRowDisableExpandCollapse
            return if not rowHeaderRows[r]

            h = rowHeaderRows[r]
            return if h.col > rowDisableAfter
            return if h.clickStatus is clickStatusCollapsed

            isRowSubtotal = h.descendants != 0
            rowspan = h.th.rowSpan 
            for i in [1..h.descendants] when h.descendants != 0
                d = rowHeaderRows[r+i]
                collapseHideDescendantRow d
            if isRowSubtotal
                collapseShowRowSubtotal h
                --rowspan
            p = h.parent
            while p
                p.th.rowSpan -= rowspan
                p = p.parent
            h.clickStatus = clickStatusCollapsed
            rowHeaderHeader = rowHeaderHeaders.hh[h.col]
            rowHeaderHeader.expandedCount--

            return if rowHeaderHeader.expandedCount != 0

            for j in [h.col..rowHeaderHeaders.hh.length-2] when j <= rowDisableAfter
                rowHeaderHeader = rowHeaderHeaders.hh[j]
                replaceClass rowHeaderHeader.th, classExpanded, classCollapsed
                rowHeaderHeader.th.textContent =
                    " " + arrowCollapsed + " " + rowHeaderHeader.th.getAttribute "data-rowAttr"
                rowHeaderHeader.clickStatuatus = clickStatusCollapsed

        showChildRow = (h) ->
            for tagName in ["td", "th"]
                cells = h.tr.getElementsByTagName tagName 
                for cell in cells
                    replaceClass cell, classRowHide, classRowShow
                    cell.style.display = "" if not hasClass cell, classColHide
            h.tr.style.display = ""

        expandShowRowSubtotal = (h) ->
            for tagName in ["td", "th"]
                cells = h.tr.getElementsByTagName tagName 
                for cell in cells
                    removeClass cell, "#{classRowCollapsed} #{classRowHide}"
                    addClass cell, "#{classRowExpanded} #{classRowShow}" 
                    cell.style.display = "" if not hasClass cell, classColHide
            h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute "data-rowHeader"
            replaceClass h.tr, classRowCollapsed, classRowExpanded

        expandHideRowSubtotal = (h) ->
            for tagName in ["td", "th"]
                cells = h.tr.getElementsByTagName tagName 
                for cell in cells
                    removeClass cell, "#{classRowCollapsed} #{classRowShow}"
                    addClass cell, "#{classRowExpanded} #{classRowHide}"
                    cell.style.display = "none"
            h.th.style.display = ""
            h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute "data-rowHeader"
            replaceClass h.tr, classRowCollapsed, classRowExpanded

        expandChildRow = (ch) ->
            if ch.descendants != 0 and hasClass(ch.th, classRowExpanded) and (isRowHideOnExpand or isRowDisable or ch.col > rowDisableAfter)
                ch.tr.style.display = ""
                ch.th.style.display = ""
            else
                showChildRow ch
            expandChildRow gch for gch in ch.children if ch.clickStatus isnt clickStatusCollapsed

        expandRow = (rowHeaderHeaders, rowHeaderRows, r) ->
            return if isRowDisable
            return if isRowDisableExpandCollapse
            return if not rowHeaderRows[r]

            h = rowHeaderRows[r]
            return if h.col > rowDisableAfter
            return if h.clickStatus is clickStatusExpanded

            isRowSubtotal = h.descendants != 0
            rowspan = 0
            for ch in h.children
                expandChildRow ch
                rowspan += ch.th.rowSpan
            h.th.rowSpan = rowspan+1
            if isRowSubtotal
                if isRowHideOnExpand
                    expandHideRowSubtotal h
                else
                    expandShowRowSubtotal h
            p = h.parent
            while p
                p.th.rowSpan += rowspan
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
            return if not rowHeaderRows[r]?

            if rowHeaderRows[r].clickStatus is clickStatusCollapsed
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
            while i < nAttrs and i <= rowDisableAfter
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
                    j = j + h.descendants + 1
                else
                    ++j

        expandRowsAt = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            return if isRowDisable
            if typeof rowAttr is 'string'
                idx = rowAttrs.indexOf rowAttr
            else
                idx = rowAttr

            return if idx < 0 or idx == rowAttrs.length-1

            for i in [0..idx]
                if i <= rowDisableAfter
                    hh = rowHeaderHeaders.hh[i]
                    replaceClass hh.th, classCollapsed, classExpanded
                    hh.th.textContent = " " + arrowExpanded + " " + rowAttrs[i]
                    hh.clickStatus = clickStatusExpanded
                j = 0
                nRows = rowHeaderRows.length
                while j < nRows
                    h = rowHeaderRows[j]
                    if h.col == i
                        expandRow(rowHeaderHeaders, rowHeaderRows, j)
                        j += h.descendants + 1
                    else
                        ++j
            ++idx
            while idx < rowAttrs.length-1 and idx <= rowDisableAfter
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
            return if isRowDisable
            return if isRowDisableExpandCollapse

            idx = rowAttrs.indexOf rowAttr
            th = rowHeaderHeaders.hh[idx]
            return if th.col > rowDisableAfter
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
                buildColHeaders colHeaderHeaders, colHeaderCols, h, rowAttrs, colAttrs for h in colHeaders
                buildColHeaderHeadersClickEvents colHeaderHeaders, colHeaderCols, colAttrs

            if rowAttrs.length > 0
                buildRowHeaderHeaders thead, rowHeaderHeaders, rowAttrs, colAttrs
                buildRowTotalsHeader rowHeaderHeaders.tr, rowAttrs, colAttrs if colAttrs.length == 0

            if colAttrs.length > 0
                buildRowTotalsHeader colHeaderHeaders[0].tr, rowAttrs, colAttrs

            tbody = createElement "tbody"
            result.appendChild tbody
            buildRowHeaders tbody, rowHeaderHeaders, rowHeaderRows, h, rowAttrs, colAttrs for h in rowHeaders if rowAttrs.length > 0
            buildRowHeaderHeadersClickEvents rowHeaderHeaders, rowHeaderRows, rowAttrs
            buildValues rowHeaderRows, colHeaderCols
            tr = buildColTotalsHeader rowAttrs, colAttrs
            buildColTotals tr, colHeaderCols if colAttrs.length > 0
            buildGrandTotal tbody, tr

            result.setAttribute "data-numrows", rowKeys.length
            result.setAttribute "data-numcols", colKeys.length
            result.style.display = "" if not opts.collapseRowsAt? and not opts.collapseColsAt?
            collapseRowsAt rowHeaderHeaders, rowHeaderRows, rowAttrs, opts.collapseRowsAt if opts.collapseRowsAt?
            if not opts.collapseColsAt?
                result.style.display = ""
                return result
            collapseColsAt colHeaderHeaders, colHeaderCols, colAttrs, opts.collapseColsAt if opts.collapseColsAt?
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

