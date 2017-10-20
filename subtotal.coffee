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

        opts.rowSubtotalDisplay = {} if not opts.rowSubtotalDisplay
        opts.rowSubtotalDisplay.disableAfter = 9999 if typeof opts.rowSubtotalDisplay.disableAfter is 'undefined'
        opts.rowSubtotalDisplay.disableFrom = if opts.rowSubtotalDisplay.disableSubtotal then 0 else opts.rowSubtotalDisplay.disableAfter + 1 if typeof opts.rowSubtotalDisplay.disableFrom is 'undefined'
        opts.colSubtotalDisplay.disableAfter = 9999 if typeof opts.colSubtotalDisplay.disableAfter is 'undefined'
        opts.colSubtotalDisplay.disableFrom = if opts.colSubtotalDisplay.disableSubtotal then 0 else opts.colSubtotalDisplay.disableAfter + 1 if typeof opts.colSubtotalDisplay.disableFrom is 'undefined'

        arrowCollapsed = opts.arrowCollapsed ?= "\u25B6"
        arrowExpanded = opts.arrowExpanded ?= "\u25E2"
        colsCollapseAt = 9999 if typeof opts.collapseColsAt is 'undefined'
        rowsCollapseAt = 9999 if typeof opts.collapseRowsAt is 'undefined'

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
            e.setAttribute a, v for own a, v of attrs

        processKeys = (keysArr, className, opts) ->
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
            console.warn tree
            return tree

        buildAxisHeader = (axisHeaders, headers, col, attrs, opts) ->
            ah =
                expandedCount: 0
                headers: []
                clickStatus: clickStatusExpanded
                onClick: collapseAxis

            arrow = "#{arrowExpanded} "
            hClass = classExpanded
            if col > opts.collapseAt
                arrow = "#{arrowCollapsed} "
                hClass = classCollapsed
                ah.clickStatus = clickStatusCollapsed
                ah.onClick = expandAxis
            if col == attrs.length-1 or col >= opts.disableFrom or opts.disableExpandCollapse
                arrow = ""
            ah.th = createElement "th", "pvtAxisLabel #{hClass}", "#{arrow}#{attrs[col]}" 
            ah.th.onclick = (event) ->
                event = event || window.event
                ah.onClick axisHeaders, headers, attrs, col, opts
            axisHeaders.push ah
            return ah 

        buildColAxisHeaders = (thead, colHeaderCols, rowAttrs, colAttrs, opts) ->
            colAxisHeaders =
                collapse: collapseCol
                expand: expandCol
                ah: []
            for attr, col in colAttrs
                ah = buildAxisHeader colAxisHeaders.ah, colHeaderCols, col, colAttrs, opts
                ah.tr = createElement "tr"
                ah.tr.appendChild createElement "th", null, null, {colspan: rowAttrs.length, rowspan: colAttrs.length} if col is 0 and rowAttrs.length isnt 0
                ah.tr.appendChild ah.th
                thead.appendChild ah.tr
            return colAxisHeaders

        buildRowAxisHeaders = (thead, rowHeaderRows, rowAttrs, colAttrs, opts) ->
            rowAxisHeaders =
                collapse: collapseCol
                expand: expandCol
                ah: []
                tr: createElement "tr"
            for col in [0..rowAttrs.length-1] 
                ah = buildAxisHeader rowAxisHeaders.ah, rowHeaderRows, col, rowAttrs, opts
                rowAxisHeaders.tr.appendChild ah.th
            if colAttrs.length != 0
                th = createElement "th"
                rowAxisHeaders.tr.appendChild ah.th
            thead.appendChild rowAxisHeaders.tr
            return rowAxisHeaders

        setHeaderAttribs = (col, label, collapse, expand, attrs, opts) ->
            hProps =
                arrow: arrowExpanded
                clickStatus: clickStatusExpanded
                onClick: collapse
                class: "#{classExpanded} "
            if col > opts.collapseAt
                hProps =
                    arrow: arrowCollapsed
                    clickStatus: clickStatusCollapsed
                    onClick: expand
                    class: "#{classCollapsed} "
            hProps.arrow = "" if col == attrs.length-1 or col >= opts.disableFrom or opts.disableExpandCollapse
            hProps.textContent = "#{hProps.arrow} #{label}"
            return hProps

        buildColHeader = (colAxisHeaders, colHeaderCols, h, rowAttrs, colAttrs, node, opts) ->
            # DF Recurse
            buildColHeader colAxisHeaders, colHeaderCols, h[chKey], rowAttrs, colAttrs, node, opts for chKey in h.children
            # Process
            ah = colAxisHeaders.ah[h.col]
            ++ah.expandedCount if h.col < opts.colSubtotalDisplay.collapseAt
            ah.headers.push h

            h.node = node.counter
            hProps = setHeaderAttribs h.col, h.text, collapseCol, expandCol, colAttrs, opts.colSubtotalDisplay
            h.onClick = hProps.onClick

            addClass h.th, "#{classColShow} col#{h.row} colcol#{h.col} #{hProps.class}"
            h.th.setAttribute "data-colnode", h.node
            h.th.colSpan = h.childrenSpan if h.children.length isnt 0
            h.th.rowSpan = 2 if h.children.length is 0 and rowAttrs.length isnt 0
            h.th.textContent = hProps.textContent
            if h.leaves > 1 and h.col < opts.colSubtotalDisplay.disableFrom and not opts.colSubtotalDisplay.disableExpandCollapse
                    h.th.onclick = (event) ->
                        event = event || window.event
                        h.onClick colAxisHeaders, colHeaderCols, h.node, opts.subtotalDisplay 
                    h.sTh = createElement "th", "pvtColLabelFiller pvtColSubtotal"
                    h.sTh.setAttribute "data-colnode", h.node
                    h.sTh.rowSpan = colAttrs.length-h.col
                    h.sTh.style.display = "none" if (opts.colSubtotalDisplay.hideOnExpand and h.col < opts.colSubtotalDisplay.collapseAt) or h.col > opts.colSubtotalDisplay.collapseAt
                    h[h.children[0]].tr.appendChild h.sTh if h.children.length isnt 0
                    h.th.colSpan++

            h.parent?.childrenSpan += h.th.colSpan

            h.clickStatus = hProps.clickStatus
            ah.tr.appendChild h.th
            h.tr = ah.tr
            colHeaderCols.push h
            node.counter++ 


        buildRowTotalsHeader = (tr, rowAttrs, colAttrs) ->
            th = createElement "th", "pvtTotalLabel rowTotal", opts.localeStrings.totals,
                rowspan: if colAttrs.length is 0 then 1 else colAttrs.length + (if rowAttrs.length is 0 then 0 else 1)
            tr.appendChild th

        buildRowHeader = (tbody, rowAxisHeaders, rowHeaderRows, h, rowAttrs, colAttrs, node) ->
            # DF Recurse
            buildRowHeader tbody, rowAxisHeaders, rowHeaderRows, h[chKey], rowAttrs, colAttrs, node for chKey in h.children
            # Process
            ah = rowAxisHeaders.ah[h.col]
            ++ah.expandedCount if h.col < rowsCollapseAt
            ah.headers.push h

            h.node = node.counter
            hProps = setHeaderAttribs h.col, h.text, collapseRow, expandRow, rowAttrs, opts.rowSubtotalDisplay
            firstChild = h[h.children[0]] if h.children.length isnt 0

            addClass h.th, "row#{h.row} rowcol#{h.col} #{classRowShow}"
            addClass h.th, "pvtRowSubtotal" if h.th.children.length isnt 0
            h.th.setAttribute "data-rownode", h.node
            h.th.colSpan = 2 if h.col is rowAttrs.length-1 and colAttrs.length isnt 0
            h.th.rowSpan = h.childrenSpan if h.children.length isnt 0

            if (opts.rowSubtotalDisplay.displayOnTop and h.children.length is 1) or (not opts.rowSubtotalDisplay.displayOnTop and h.children.length isnt 0)
                h.tr = firstChild.tr
                h.tr.insertBefore h.th, firstChild.th
                h.sTh = firstChild.sTh
            else
                h.tr = createElement "tr", "pvtRowSubtotal row#{h.row}"
                h.tr.appendChild h.th

            if h.leaves > 1 and h.col < opts.rowSubtotalDisplay.disableFrom
                if not opts.rowSubtotalDisplay.disableExpandCollapse
                    addClass h.th, hProps.class
                    h.th.textContent = "#{hProps.arrow} #{h.text}"
                    h.th.onclick = (event) ->
                        event = event || window.event
                        h.onClick rowAxisHeaders, rowHeaderRows, h.node

                if h.children.length > 1
                    h.sTh = createElement "th", "pvtRowLabelFiller pvtRowSubtotal row#{h.row} rowcol#{h.col} #{hProps.class}"
                    h.sTh.setAttribute "data-rownode", h.node
                    h.sTh.colSpan = rowAttrs.length-(h.col+1) + if colAttrs.length != 0 then 1 else 0 
                    h.sTh.style.display = "none" if (opts.rowSubtotalDisplay.hideOnExpand and h.col < opts.rowSubtotalDisplay.collapseAt) or h.col > opts.rowSubtotalDisplay.collapseAt
                    h.th.rowSpan++

                    addClass h.tr, hProps.class
                    if opts.rowSubtotalDisplay.displayOnTop
                        h.tr.appendChild h.sTh
                    else
                        h.sTr = createElement "tr", "pvtRowSubtotal row#{h.row} #{hProps.class}"
                        h.sTr.appendChild h.sTh
                        tbody.appendChild h.sTr
                tbody.insertBefore h.tr, firstChild.tr
            else
                tbody.appendChild h.tr if h.children.length is 0

            h.parent?.childrenSpan += h.th.rowSpan

            h.clickStatus = hProps.clickStatus
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
            for h in colHeaderCols when h.leaves isnt 1
                colInit = setColInitParams h.col
                clsNames = "pvtVal pvtTotal colTotal #{colInit.colClass} col#{h.row} colcol#{h.col}"
                clsNames += " pvtColSubtotal" if h.children.length isnt 0 
                totalAggregator = colTotals[h.flatKey]
                val = totalAggregator.value()
                td = createElement "td", clsNames, totalAggregator.format(val),
                    "data-value": val
                    "data-for": "col#{h.col}"
                    "data-colnode": "#{h.node}", getTableEventHandlers val, [], h.key
                td.style.display = "none" if (h.col > colsCollapseAt) or (h.children.length isnt 0 and (isColDisable or h.col > colDisableAfter or (isColHideOnExpand and h.col < colsCollapseAt)))
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
            h.th.textContent = " " + arrowCollapsed + " " + h.text
            h.th.colSpan = 1

        collapseChildCol = (ch, h) ->
            for chKey in ch.children
                collapseChildCol ch[chKey], h

            hideDescendantCol ch

        collapseCol = (axisHeaders, headers, c, opts) ->
            h = headers[c]
            colSpan = h.th.colSpan - 1
            for chKey in h.children
                ch = h[chKey]
                collapseChildCol ch, h

            collapseShowColSubtotal h

            p = h.parent
            while p isnt null
                p.th.colSpan -= colSpan
                p = p.parent
            h.clickStatus = clickStatusCollapsed
            ah = axisHeaders[h.col]
            ah.expandedCount--
            if ah.expandedCount == 0
                for i in [h.col..ah.length-2] when i < opts.disableFrom
                    ah = axisHeaders[i]
                    replaceClass ah.th, classExpanded, classCollapsed
                    ah.th.textContent = " " + arrowCollapsed + " " + ah.text
                    ah.clickStatus = clickStatusCollapsed

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
            expandChildCol ch[chKey] for chKey in ch.children if ch.clickStatus isnt clickStatusCollapsed

        expandCol = (colAxisHeaders, colHeaderCols, c, opts) ->
            return if isColDisable or isColDisableExpandCollapse or not colHeaderCols[c]

            h = colHeaderCols[c]
            return if h.col >= colDisableFrom or h.clickStatus is clickStatusExpanded

            colSpan = 0
            for chKey in h.children
                ch = h[chKey]
                expandChildCol ch
                colSpan += ch.th.colSpan
            h.th.colSpan = colSpan
            if h.children.length isnt 0
                replaceClass h.th, classColCollapsed, classColExpanded
                h.th.textContent = " " + arrowExpanded + " " + h.text
                if isColHideOnExpand
                    expandHideColSubtotal h
                    --colspan
                else
                    expandShowColSubtotal h
            p = h.parent
            while p
                p.th.colSpan += colSpan
                p = p.parent
            h.clickStatus = clickStatusExpanded
            ah = colAxisHeaders[h.col]
            ++ah.expandedCount
            if ah.expandedCount is ah.headers.length
                replaceClass ah.th, classCollapsed, classExpanded
                ah.th.textContent = " " + arrowExpanded + " " + ah.th.getAttribute "data-colAttr"
                ah.clickStatus = clickStatusExpanded

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

        collapseRow = (rowAxisHeaders, rowHeaderRows, r, opts) ->
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

            ah = rowAxisHeaders.ah[h.col]
            ah.expandedCount--

            return if ah.expandedCount != 0

            for j in [h.col..rowAxisHeaders.ah.length-2] when j < rowDisableFrom
                ah = rowAxisHeaders.ah[j]
                replaceClass ah.th, classExpanded, classCollapsed
                ah.th.textContent = " " + arrowCollapsed + " " + ah.th.getAttribute "data-rowAttr"
                ah.clickStatus = clickStatusCollapsed

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

        expandRow = (rowAxisHeaders, rowHeaderRows, r, opts) ->
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
            ah = rowAxisHeaders.ah[h.col]
            ++ah.expandedCount
            if ah.expandedCount == ah.headers.length
                replaceClass ah.th, classCollapsed, classExpanded
                ah.th.textContent = " " + arrowExpanded + " " + ah.th.getAttribute "data-rowAttr"
                ah.clickStatus = clickStatusExpanded

        collapseAxis = (axisHeaders, headers, attrs, attr, opts) ->
            return if opts.disableExpandCollapse

            idx = attr
            idx = attrs.indexOf attr if typeof attr is 'string'
            n = attrs.length-2
            return if idx < 0 or n < idx or idx >= opts.disableFrom

            for i in [idx..n]
                ah = axisHeaders[i]
                replaceClass ah.th, classExpanded, classCollapsed
                ah.th.textContent = " " + arrowCollapsed + " " + attrs[i]
                ah.clickStatus = clickStatusCollapsed

                ah.collapse axisHeaders, headers, h.node, opts for h in ah.headers when h.clickStatus isnt clickStatusCollapsed and h.th.style.display isnt "none" and h.leaves > 1

        expandAxis = (axisHeaders, headerNodes, attrs, attr, expand, opts) ->
            return if opts.disableExpandCollapse

            idx = attr
            idx = attrs.indexOf attr if typeof attr is 'string'
            return if idx < 0 or idx == attrs.length-1 or i >= opts.disableFrom

            for i in [0..idx] when i < opts.disableFrom
                ah = axisHeaders[i]
                replaceClass ah.th, classCollapsed, classExpanded
                ah.th.textContent = " " + arrowExpanded + " " + attrs[i]
                ah.clickStatus = clickStatusExpanded

                ah.expand axisHeaders, headerNodes, h.node for h in ah.headers when h.leaves > 1

            ++idx
            while idx < attrs.length-1 and idx < opts.disableFrom
                ah = axisHeaders[idx]
                if ah.expandedCount == 0
                    replaceClass ah.th, classExpanded, classCollapsed
                    ah.th.textContent = " " + arrowCollapsed + " " + attrs[idx]
                    ah.clickStatus = clickStatusCollapsed
                else if ah.expandedCount == ah.nodes.length
                    replaceClass ah.th, classCollapsed, classExpanded
                    ah.th.textContent = " " + arrowExpanded + " " + attrs[idx]
                    ah.clickStatus = clickStatusExpanded
                ++idx

        main = (rowAttrs, rowKeys, colAttrs, colKeys) ->
            rowHeaderRows = []
            colHeaderCols = []

            colHeaders = processKeys colKeys, "pvtColLabel" if colAttrs.length isnt 0 and colKeys.length isnt 0
            rowHeaders = processKeys rowKeys, "pvtRowLabel" if rowAttrs.length isnt 0 and rowKeys.length isnt 0

            result = createElement "table", "pvtTable", null, {style: "display: none;"}

            thead = createElement "thead"
            result.appendChild thead

            if colAttrs.length isnt 0
                colAxisHeaders = buildColAxisHeaders thead, colHeaderCols, rowAttrs, colAttrs, opts
                node = counter: 0
                buildColHeader colAxisHeaders, colHeaderCols, colHeaders[chKey], rowAttrs, colAttrs, node, opts for chKey in colHeaders.children

            if rowAttrs.length isnt 0
                rowAxisHeaders = buildRowAxisHeaders thead, rowHeaderRows, rowAttrs, colAttrs, opts
                buildRowTotalsHeader rowAxisHeaders.tr, rowAttrs, colAttrs if colAttrs.length is 0

            if colAttrs.length isnt 0
                buildRowTotalsHeader colAxisHeaders.ah[0].tr, rowAttrs, colAttrs


            tbody = createElement "tbody"
            result.appendChild tbody
            node = counter: 0
            buildRowHeader tbody, rowAxisHeaders, rowHeaderRows, rowHeaders[chKey], rowAttrs, colAttrs, node for chKey in rowHeaders.children if rowAttrs.length > 0
            # buildValues tbody, rowHeaderRows, colHeaderCols
            tr = buildColTotalsHeader rowAttrs, colAttrs
            # buildColTotals tr, colHeaderCols if colAttrs.length > 0
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

