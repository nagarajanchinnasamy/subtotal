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
            localeStrings: totals: "Totals", subtotalOf: "Subtotal of"
            arrowCollapsed: "\u25B6"
            arrowExpanded: "\u25E2"
            rowSubtotalDisplay:
                displayOnTop: true
                disableFrom: 99999
                collapseAt: 99999
                hideOnExpand: false
                disableExpandCollapse: false
            colSubtotalDisplay:
                displayOnTop: true
                disableFrom: 99999
                collapseAt: 99999
                hideOnExpand: false
                disableExpandCollapse: false
        opts = $.extend true, {}, defaults, opts

        opts.rowSubtotalDisplay.disableFrom = 0 if opts.rowSubtotalDisplay.disableSubtotal
        opts.rowSubtotalDisplay.disableFrom = opts.rowSubtotalDisplay.disableAfter+1 if typeof  opts.rowSubtotalDisplay.disableAfter isnt 'undefined' and opts.rowSubtotalDisplay.disableAfter isnt null
        opts.rowSubtotalDisplay.collapseAt = opts.collapseRowsAt if typeof opts.rowSubtotalDisplay.collapseAt isnt 'undefined' and opts.collapseRowsAt isnt null

        opts.colSubtotalDisplay.disableFrom = 0 if opts.colSubtotalDisplay.disableSubtotal
        opts.colSubtotalDisplay.disableFrom = opts.colSubtotalDisplay.disableAfter+1 if typeof  opts.colSubtotalDisplay.disableAfter isnt 'undefined' and opts.colSubtotalDisplay.disableAfter isnt null
        opts.colSubtotalDisplay.collapseAt = opts.collapseColsAt if typeof opts.colSubtotalDisplay.collapseAt isnt 'undefined' and opts.collapseColsAt isnt null

        colAttrs = pivotData.colAttrs
        rowAttrs = pivotData.rowAttrs
        rowKeys = pivotData.getRowKeys()
        colKeys = pivotData.getColKeys()
        tree = pivotData.tree
        rowTotals = pivotData.rowTotals
        colTotals = pivotData.colTotals
        allTotal = pivotData.allTotal

        classRowHide = "rowhide"
        classRowShow = "rowshow"
        classColHide = "colhide"
        classColShow = "colshow"
        clickStatusExpanded = "expanded"
        clickStatusCollapsed = "collapsed"
        classExpanded = "expanded"
        classCollapsed = "collapsed"
        classRowExpanded = "rowexpanded"
        classRowCollapsed = "rowcollapsed"
        classColExpanded = "colexpanded"
        classColCollapsed = "colcollapsed"
        arrowExpanded = opts.arrowExpanded
        arrowCollapsed = opts.arrowCollapsed

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
            headers = children: []
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
                                node = headers
                                for i in [0..lastIdx-1] when lastIdx > 0
                                    node[k0[i]].leaves++
                                    if not node[k0[i]].firstLeaf 
                                        node[k0[i]].firstLeaf = acc[curVal]
                                    node = node[k0[i]]
                                return headers
                            return acc[curVal]
                        headers)
                    row++
                    return headers
                headers)
            return headers

        buildAxisHeader = (axisHeaders, col, attrs, opts) ->
            ah =
                text: attrs[col]
                expandedCount: 0
                expandables: 0
                attrHeaders: []
                clickStatus: clickStatusExpanded
                onClick: collapseAxis

            arrow = "#{arrowExpanded} "
            hClass = classExpanded
            if col >= opts.collapseAt
                arrow = "#{arrowCollapsed} "
                hClass = classCollapsed
                ah.clickStatus = clickStatusCollapsed
                ah.onClick = expandAxis
            if col == attrs.length-1 or col >= opts.disableFrom or opts.disableExpandCollapse
                arrow = ""
            ah.th = createElement "th", "pvtAxisLabel #{hClass}", "#{arrow}#{ah.text}" 
            if col < attrs.length-1 and col < opts.disableFrom and not opts.disableExpandCollapse
                ah.th.onclick = (event) ->
                    event = event || window.event
                    ah.onClick axisHeaders, col, attrs, opts
            axisHeaders.ah.push ah
            return ah 

        buildColAxisHeaders = (thead, rowAttrs, colAttrs, opts) ->
            axisHeaders =
                collapseAttrHeader: collapseCol
                expandAttrHeader: expandCol
                ah: []
            for attr, col in colAttrs
                ah = buildAxisHeader axisHeaders, col, colAttrs, opts.colSubtotalDisplay
                ah.tr = createElement "tr"
                ah.tr.appendChild createElement "th", null, null, {colspan: rowAttrs.length, rowspan: colAttrs.length} if col is 0 and rowAttrs.length isnt 0
                ah.tr.appendChild ah.th
                thead.appendChild ah.tr
            return axisHeaders

        buildRowAxisHeaders = (thead, rowAttrs, colAttrs, opts) ->
            axisHeaders =
                collapseAttrHeader: collapseRow
                expandAttrHeader: expandRow
                ah: []
                tr: createElement "tr"
            for col in [0..rowAttrs.length-1] 
                ah = buildAxisHeader axisHeaders, col, rowAttrs, opts.rowSubtotalDisplay
                axisHeaders.tr.appendChild ah.th
            if colAttrs.length != 0
                th = createElement "th"
                axisHeaders.tr.appendChild th
            thead.appendChild axisHeaders.tr
            return axisHeaders

        getHeaderText = (h, attrs, opts) ->
            arrow = " #{arrowExpanded} "
            arrow = "" if h.col == attrs.length-1 or h.col >= opts.disableFrom or opts.disableExpandCollapse or h.children.length is 0
            return "#{arrow}#{h.text}"

        buildColHeader = (axisHeaders, attrHeaders, h, rowAttrs, colAttrs, node, opts) ->
            # DF Recurse
            buildColHeader axisHeaders, attrHeaders, h[chKey], rowAttrs, colAttrs, node, opts for chKey in h.children
            # Process
            ah = axisHeaders.ah[h.col]
            ah.attrHeaders.push h

            h.node = node.counter
            h.onClick = collapseCol

            addClass h.th, "#{classColShow} col#{h.row} colcol#{h.col} #{classColExpanded}"
            h.th.setAttribute "data-colnode", h.node
            h.th.colSpan = h.childrenSpan if h.children.length isnt 0
            h.th.rowSpan = 2 if h.children.length is 0 and rowAttrs.length isnt 0
            h.th.textContent = getHeaderText h, colAttrs, opts.colSubtotalDisplay
            if h.children.length isnt 0 and h.col < opts.colSubtotalDisplay.disableFrom
                    ah.expandables++
                    ah.expandedCount += 1
                    h.th.colSpan++ if not opts.colSubtotalDisplay.hideOnExpand
                    if not opts.colSubtotalDisplay.disableExpandCollapse
                        h.th.onclick = (event) ->
                            event = event || window.event
                            h.onClick axisHeaders, h, opts.colSubtotalDisplay 
                    h.sTh = createElement "th", "pvtColLabelFiller #{classColShow} col#{h.row} colcol#{h.col} #{classColExpanded}"
                    h.sTh.setAttribute "data-colnode", h.node
                    h.sTh.rowSpan = colAttrs.length-h.col
                    replaceClass h.sTh, classColShow, classColHide if opts.colSubtotalDisplay.hideOnExpand
                    h[h.children[0]].tr.appendChild h.sTh

            h.parent?.childrenSpan += h.th.colSpan

            h.clickStatus = clickStatusExpanded
            ah.tr.appendChild h.th
            h.tr = ah.tr
            attrHeaders.push h
            node.counter++ 


        buildRowTotalsHeader = (tr, rowAttrs, colAttrs) ->
            th = createElement "th", "pvtTotalLabel rowTotal", opts.localeStrings.totals,
                rowspan: if colAttrs.length is 0 then 1 else colAttrs.length + (if rowAttrs.length is 0 then 0 else 1)
            tr.appendChild th

        buildRowHeader = (tbody, axisHeaders, attrHeaders, h, rowAttrs, colAttrs, node, opts) ->
            # DF Recurse
            buildRowHeader tbody, axisHeaders, attrHeaders, h[chKey], rowAttrs, colAttrs, node, opts for chKey in h.children
            # Process
            ah = axisHeaders.ah[h.col]
            ah.attrHeaders.push h

            h.node = node.counter
            h.onClick = collapseRow
            firstChild = h[h.children[0]] if h.children.length isnt 0

            addClass h.th, "#{classRowShow} row#{h.row} rowcol#{h.col} #{classRowExpanded}"
            h.th.setAttribute "data-rownode", h.node
            h.th.colSpan = 2 if h.col is rowAttrs.length-1 and colAttrs.length isnt 0
            h.th.rowSpan = h.childrenSpan if h.children.length isnt 0
            h.th.textContent = getHeaderText h, rowAttrs, opts.rowSubtotalDisplay

            h.tr = createElement "tr", "row#{h.row}"
            h.tr.appendChild h.th
            if h.children.length is 0
                tbody.appendChild h.tr
            else
                tbody.insertBefore h.tr, firstChild.tr
            
            if h.children.length isnt 0 and h.col < opts.rowSubtotalDisplay.disableFrom
                ++ah.expandedCount
                ++ah.expandables
                if not opts.rowSubtotalDisplay.disableExpandCollapse
                    h.th.onclick = (event) ->
                        event = event || window.event
                        h.onClick axisHeaders, h, opts.rowSubtotalDisplay

                h.sTh = createElement "th", "pvtRowLabelFiller row#{h.row} rowcol#{h.col} #{classRowExpanded} #{classRowShow}"
                replaceClass h.sTh, classRowShow, classRowHide if opts.rowSubtotalDisplay.hideOnExpand
                h.sTh.setAttribute "data-rownode", h.node
                h.sTh.colSpan = rowAttrs.length-(h.col+1) + if colAttrs.length != 0 then 1 else 0 

                if opts.rowSubtotalDisplay.displayOnTop
                    h.tr.appendChild h.sTh
                else
                    h.th.rowSpan += 1 # if not opts.rowSubtotalDisplay.hideOnExpand
                    h.sTr = createElement "tr", "row#{h.row}"
                    h.sTr.appendChild h.sTh
                    tbody.appendChild h.sTr

            h.th.rowSpan++ if h.children.length isnt 0
            h.parent?.childrenSpan += h.th.rowSpan

            h.clickStatus = clickStatusExpanded
            attrHeaders.push h
            node.counter++

        getTableEventHandlers = (value, rowKey, colKey, rowAttrs, colAttrs, opts) ->
            return if not opts.table?.eventHandlers
            eventHandlers = {}
            for own event, handler of opts.table.eventHandlers
                filters = {}
                filters[attr] = colKey[i] for own i, attr of colAttrs when colKey[i]?
                filters[attr] = rowKey[i] for own i, attr of rowAttrs when rowKey[i]?
                eventHandlers[event] = (e) -> handler(e, value, filters, pivotData)
            return eventHandlers

        buildValues = (tbody, colAttrHeaders, rowAttrHeaders, rowAttrs, colAttrs, opts) ->
            for rh in rowAttrHeaders when rh.col is rowAttrs.length-1 or (rh.children.length isnt 0 and rh.col < opts.rowSubtotalDisplay.disableFrom)
                rCls = "pvtVal row#{rh.row} rowcol#{rh.col} #{classRowExpanded}"
                if rh.children.length > 0
                    rCls += " pvtRowSubtotal"
                    rCls += if opts.rowSubtotalDisplay.hideOnExpand then " #{classRowHide}" else "  #{classRowShow}"
                else
                    rCls += " #{classRowShow}"
                tr = if rh.sTr then rh.sTr else rh.tr
                for ch in colAttrHeaders when ch.col is colAttrs.length-1 or (ch.children.length isnt 0 and ch.col < opts.colSubtotalDisplay.disableFrom)
                    aggregator = tree[rh.flatKey][ch.flatKey] ? {value: (-> null), format: -> ""}
                    val = aggregator.value()
                    cls = " #{rCls} col#{ch.row} colcol#{ch.col} #{classColExpanded}"
                    if ch.children.length > 0
                        cls += " pvtColSubtotal"
                        cls += if opts.colSubtotalDisplay.hideOnExpand then " #{classColHide}" else " #{classColShow}"
                    else
                        cls += " #{classColShow}"
                    td = createElement "td", cls, aggregator.format(val),
                        "data-value": val
                        "data-rownode": rh.node
                        "data-colnode": ch.node,
                        getTableEventHandlers val, rh.key, ch.key, rowAttrs, colAttrs, opts

                    tr.appendChild td

                # buildRowTotal
                totalAggregator = rowTotals[rh.flatKey]
                val = totalAggregator.value()
                td = createElement "td", "pvtTotal rowTotal #{rCls}", totalAggregator.format(val),
                    "data-value": val
                    "data-row": "row#{rh.row}"
                    "data-rowcol": "col#{rh.col}"
                    "data-rownode": rh.node,
                    getTableEventHandlers val, rh.key, [], rowAttrs, colAttrs, opts
                tr.appendChild td

        buildColTotalsHeader = (rowAttrs, colAttrs) ->
            tr = createElement "tr"
            colspan = rowAttrs.length + (if colAttrs.length == 0 then 0 else 1)
            th = createElement "th", "pvtTotalLabel colTotal", opts.localeStrings.totals, {colspan: colspan}
            tr.appendChild th
            return tr

        buildColTotals = (tr, attrHeaders, rowAttrs, colAttrs, opts) ->
            for h in attrHeaders when  h.col is colAttrs.length-1 or (h.children.length isnt 0 and h.col < opts.colSubtotalDisplay.disableFrom)
                clsNames = "pvtVal pvtTotal colTotal #{classColExpanded} col#{h.row} colcol#{h.col}"
                if h.children.length isnt 0
                    clsNames += " pvtColSubtotal" 
                    clsNames += if opts.colSubtotalDisplay.hideOnExpand then " #{classColHide}" else " #{classColShow}"
                else
                    clsNames += " #{classColShow}"
                totalAggregator = colTotals[h.flatKey]
                val = totalAggregator.value()
                td = createElement "td", clsNames, totalAggregator.format(val),
                    "data-value": val
                    "data-for": "col#{h.col}"
                    "data-colnode": "#{h.node}",
                    getTableEventHandlers val, [], h.key, rowAttrs, colAttrs, opts
                tr.appendChild td

        buildGrandTotal = (tbody, tr, rowAttrs, colAttrs, opts) ->
            totalAggregator = allTotal
            val = totalAggregator.value()
            td = createElement "td", "pvtGrandTotal", totalAggregator.format(val),
                {"data-value": val},
                getTableEventHandlers val, [], [], rowAttrs, colAttrs, opts
            tr.appendChild td
            tbody.appendChild tr

        collapseAxisHeaders = (axisHeaders, col, opts) ->
            collapsible = Math.min axisHeaders.ah.length-2, opts.disableFrom-1
            return if col > collapsible
            for i in [col..collapsible]
                ah = axisHeaders.ah[i]
                replaceClass ah.th, classExpanded, classCollapsed
                ah.th.textContent = " #{arrowCollapsed} #{ah.text}"
                ah.clickStatus = clickStatusCollapsed
                ah.onClick = expandAxis

        adjustAxisHeader = (axisHeaders, col, opts) ->
            ah = axisHeaders.ah[col]
            if ah.expandedCount is 0
                collapseAxisHeaders axisHeaders, col, opts
            else if ah.expandedCount is ah.expandables
                replaceClass ah.th, classCollapsed, classExpanded
                ah.th.textContent = " #{arrowExpanded} #{ah.text}"
                ah.clickStatus = clickStatusExpanded
                ah.onClick = collapseAxis

        hideChildCol = (ch) ->
            $(ch.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{ch.node}\"], th[data-colnode=\"#{ch.node}\"]" 
                .removeClass classColShow 
                .addClass classColHide

        collapseHiddenColSubtotal = (h, opts) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass classColExpanded
                .addClass classColCollapsed
            h.th.textContent = " #{arrowCollapsed} #{h.text}" if h.children.length isnt 0
            h.th.colSpan = 1
            
        collapseShowColSubtotal = (h, opts) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass classColExpanded
                .addClass classColCollapsed
                .removeClass classColHide
                .addClass classColShow
            h.th.textContent = " #{arrowCollapsed} #{h.text}" if h.children.length isnt 0
            h.th.colSpan = 1

        collapseChildCol = (ch, h) ->
            collapseChildCol ch[chKey], h for chKey in ch.children when hasClass ch[chKey].th, classColShow
            hideChildCol ch

        collapseCol = (axisHeaders, h, opts) ->
            colSpan = h.th.colSpan - 1
            collapseChildCol h[chKey], h for chKey in h.children when hasClass h[chKey].th, classColShow
            if h.col < opts.disableFrom
                if hasClass h.th, classColHide
                    collapseHiddenColSubtotal h, opts
                else 
                    collapseShowColSubtotal h, opts
            p = h.parent
            while p
                p.th.colSpan -= colSpan
                p = p.parent
            h.clickStatus = clickStatusCollapsed
            h.onClick = expandCol
            axisHeaders.ah[h.col].expandedCount--
            adjustAxisHeader axisHeaders, h.col, opts

        showChildCol = (ch) ->
            $(ch.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{ch.node}\"], th[data-colnode=\"#{ch.node}\"]" 
                .removeClass classColHide
                .addClass classColShow

        expandHideColSubtotal = (h) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass "#{classColCollapsed} #{classColShow}" 
                .addClass "#{classColExpanded} #{classColHide}" 
            replaceClass h.th, classColHide, classColShow
            h.th.textContent = " #{arrowExpanded} #{h.text}"

        expandShowColSubtotal = (h) ->
            $(h.th).closest 'table.pvtTable'
                .find "tbody tr td[data-colnode=\"#{h.node}\"], th[data-colnode=\"#{h.node}\"]" 
                .removeClass "#{classColCollapsed} #{classColHide}"
                .addClass "#{classColExpanded} #{classColShow}"
            h.th.colSpan++
            h.th.textContent = " #{arrowExpanded} #{h.text}"

        expandChildCol = (ch, opts) ->
            if ch.children.length isnt 0 and opts.hideOnExpand and ch.clickStatus is clickStatusExpanded
                replaceClass ch.th, classColHide, classColShow
            else
                showChildCol ch
            if ch.sTh and ch.clickStatus is clickStatusExpanded and opts.hideOnExpand
                replaceClass ch.sTh, classColShow, classColHide
            expandChildCol ch[chKey], opts for chKey in ch.children if (ch.clickStatus is clickStatusExpanded or ch.col >= opts.disableFrom)
            
        expandCol = (axisHeaders, h, opts) ->
            if h.clickStatus is clickStatusExpanded
                adjustAxisHeader axisHeaders, h.col, opts
                return
            colSpan = 0
            for chKey in h.children
                ch = h[chKey]
                expandChildCol ch, opts
                colSpan += ch.th.colSpan
            h.th.colSpan = colSpan

            if h.col < opts.disableFrom
                if opts.hideOnExpand
                    expandHideColSubtotal h
                    --colSpan
                else
                    expandShowColSubtotal h
            p = h.parent
            while p
                p.th.colSpan += colSpan
                p = p.parent
            h.clickStatus = clickStatusExpanded
            h.onClick = collapseCol
            axisHeaders.ah[h.col].expandedCount++
            adjustAxisHeader axisHeaders, h.col, opts

        hideChildRow = (ch, opts) ->
            replaceClass cell, classRowShow, classRowHide for cell in ch.tr.querySelectorAll "th, td"
            replaceClass cell, classRowShow, classRowHide for cell in ch.sTr.querySelectorAll "th, td" if ch.sTr

        collapseShowRowSubtotal = (h, opts) ->
            h.th.textContent = " #{arrowCollapsed} #{h.text}"
            for cell in h.tr.querySelectorAll "th, td"
                removeClass cell, "#{classRowExpanded} #{classRowHide}"
                addClass cell, "#{classRowCollapsed} #{classRowShow}"
            if h.sTr
                for cell in h.sTr.querySelectorAll "th, td"
                    removeClass cell, "#{classRowExpanded} #{classRowHide}"
                    addClass cell, "#{classRowCollapsed} #{classRowShow}"

        collapseChildRow = (ch, h, opts) ->
            collapseChildRow ch[chKey], h, opts for chKey in ch.children
            hideChildRow ch, opts

        collapseRow = (axisHeaders, h, opts) ->
            collapseChildRow h[chKey], h, opts for chKey in h.children
            collapseShowRowSubtotal h, opts
            h.clickStatus = clickStatusCollapsed
            h.onClick = expandRow
            axisHeaders.ah[h.col].expandedCount--
            adjustAxisHeader axisHeaders, h.col, opts

        showChildRow = (ch, opts) ->
            replaceClass cell, classRowHide, classRowShow for cell in ch.tr.querySelectorAll "th, td"
            replaceClass cell, classRowHide, classRowShow for cell in ch.sTr.querySelectorAll "th, td" if ch.sTr

        expandShowRowSubtotal = (h, opts) ->
            h.th.textContent = " #{arrowExpanded} #{h.text}"
            for cell in h.tr.querySelectorAll "th, td"
                removeClass cell, "#{classRowCollapsed} #{classRowHide}"
                addClass cell, "#{classRowExpanded} #{classRowShow}"
            if h.sTr
                for cell in h.sTr.querySelectorAll "th, td"
                    removeClass cell, "#{classRowCollapsed} #{classRowHide}"
                    addClass cell, "#{classRowExpanded} #{classRowShow}"

        expandHideRowSubtotal = (h, opts) ->
            h.th.textContent = " #{arrowExpanded} #{h.text}"
            for cell in h.tr.querySelectorAll "th, td"
                removeClass cell, "#{classRowCollapsed} #{classRowShow}"
                addClass cell, "#{classRowExpanded} #{classRowHide}"
            removeClass h.th, "#{classRowCollapsed} #{classRowHide}"
            addClass cell, "#{classRowExpanded} #{classRowShow}"
            if h.sTr
                for cell in h.sTr.querySelectorAll "th, td"
                    removeClass cell, "#{classRowCollapsed} #{classRowShow}"
                    addClass cell, "#{classRowExpanded} #{classRowHide}"

        expandChildRow = (ch, opts) ->
            if ch.children.length isnt 0 and opts.hideOnExpand and ch.clickStatus is clickStatusExpanded
                replaceClass ch.th, classRowHide, classRowShow
            else
                showChildRow ch, opts
            if ch.sTh and ch.clickStatus is clickStatusExpanded and opts.hideOnExpand
                replaceClass ch.sTh, classRowShow, classRowHide
            expandChildRow ch[chKey], opts for chKey in ch.children if (ch.clickStatus is clickStatusExpanded or ch.col >= opts.disableFrom)

        expandRow = (axisHeaders, h, opts) ->
            if h.clickStatus is clickStatusExpanded
                adjustAxisHeader axisHeaders, h.col, opts
                return
            for chKey in h.children
                ch = h[chKey]
                expandChildRow ch, opts
            if h.children.length isnt 0 
                if opts.hideOnExpand
                    expandHideRowSubtotal h, opts
                else
                    expandShowRowSubtotal h, opts
            h.clickStatus = clickStatusExpanded
            h.onClick = collapseRow
            axisHeaders.ah[h.col].expandedCount++
            adjustAxisHeader axisHeaders, h.col, opts
    
        collapseAxis = (axisHeaders, col, attrs, opts) ->
            collapsible = Math.min attrs.length-2, opts.disableFrom-1
            return if col > collapsible
            axisHeaders.collapseAttrHeader axisHeaders, h, opts for h in axisHeaders.ah[i].attrHeaders when h.clickStatus is clickStatusExpanded and h.children.length isnt 0 for i in [collapsible..col] by -1

        expandAxis = (axisHeaders, col, attrs, opts) ->
            ah = axisHeaders.ah[col]
            axisHeaders.expandAttrHeader axisHeaders, h, opts for h in axisHeaders.ah[i].attrHeaders for i in [0..col] 
            # when h.clickStatus is clickStatusCollapsed and h.children.length isnt 0 for i in [0..col] 

        main = (rowAttrs, rowKeys, colAttrs, colKeys) ->
            rowAttrHeaders = []
            colAttrHeaders = []

            colKeyHeaders = processKeys colKeys, "pvtColLabel" if colAttrs.length isnt 0 and colKeys.length isnt 0
            rowKeyHeaders = processKeys rowKeys, "pvtRowLabel" if rowAttrs.length isnt 0 and rowKeys.length isnt 0

            result = createElement "table", "pvtTable", null, {style: "display: none;"}

            thead = createElement "thead"
            result.appendChild thead

            if colAttrs.length isnt 0
                colAxisHeaders = buildColAxisHeaders thead, rowAttrs, colAttrs, opts
                node = counter: 0
                buildColHeader colAxisHeaders, colAttrHeaders, colKeyHeaders[chKey], rowAttrs, colAttrs, node, opts for chKey in colKeyHeaders.children
                buildRowTotalsHeader colAxisHeaders.ah[0].tr, rowAttrs, colAttrs

            tbody = createElement "tbody"
            result.appendChild tbody
            if rowAttrs.length isnt 0
                rowAxisHeaders = buildRowAxisHeaders thead, rowAttrs, colAttrs, opts
                buildRowTotalsHeader rowAxisHeaders.tr, rowAttrs, colAttrs if colAttrs.length is 0
                node = counter: 0
                buildRowHeader tbody, rowAxisHeaders, rowAttrHeaders, rowKeyHeaders[chKey], rowAttrs, colAttrs, node, opts for chKey in rowKeyHeaders.children

            buildValues tbody, colAttrHeaders, rowAttrHeaders, rowAttrs, colAttrs, opts
            tr = buildColTotalsHeader rowAttrs, colAttrs
            buildColTotals tr, colAttrHeaders, rowAttrs, colAttrs, opts if colAttrs.length > 0
            buildGrandTotal tbody, tr, rowAttrs, colAttrs, opts

            collapseAxis colAxisHeaders, opts.colSubtotalDisplay.collapseAt, colAttrs, opts.colSubtotalDisplay
            collapseAxis rowAxisHeaders, opts.rowSubtotalDisplay.collapseAt, rowAttrs, opts.rowSubtotalDisplay

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
    # Aggregators
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

