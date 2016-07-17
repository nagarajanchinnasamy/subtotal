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
            super(input, opts)

        processKey = (record, totals, keys, attrs, f) ->
            key = []
            addKey = false
            for attr in attrs
                key.push record[attr] ? "null" 
                flatKey = key.join(String.fromCharCode(0))
                if not totals[flatKey]
                    totals[flatKey] = f(key.slice())
                    addKey = true
                totals[flatKey].push record
            if addKey
                keys.push key
            return key

        processRecord: (record) -> #this code is called in a tight loop
            rowKey = []
            colKey = []
            
            @allTotal.push record
            rowKey = processKey record, @rowTotals, @rowKeys, @rowAttrs, (key) =>
                    return @aggregator(this, key, [])
            colKey = processKey record, @colTotals, @colKeys, @colAttrs, (key) =>
                    return @aggregator(this, [], key)
            m = rowKey.length-1
            n = colKey.length-1            
            if m < 0 or n < 0
                return
            for i in [0..m]
                fRowKey = rowKey.slice(0, i+1)
                flatRowKey = fRowKey.join(String.fromCharCode(0))
                if not @tree[flatRowKey]
                    @tree[flatRowKey] = {}
                for j in [0..n]
                    fColKey = colKey.slice(0, j+1)
                    flatColKey = fColKey.join(String.fromCharCode(0))
                    if not @tree[flatRowKey][flatColKey]
                        @tree[flatRowKey][flatColKey] = @aggregator(this, fRowKey, fColKey)
                    @tree[flatRowKey][flatColKey].push record

    $.pivotUtilities.SubtotalPivotData = SubtotalPivotData

    SubtotalRenderer = (pivotData, opts) ->
        defaults =
            localeStrings:
                totals: "Totals"

        opts = $.extend defaults, opts

        arrowCollapsed = "\u25B6"
        arrowExpanded = "\u25E2"
        colAttrs = pivotData.colAttrs
        rowAttrs = pivotData.rowAttrs
        rowKeys = pivotData.getRowKeys()
        colKeys = pivotData.getColKeys()
        tree = pivotData.tree
        rowTotals = pivotData.rowTotals
        colTotals = pivotData.colTotals
        allTotal =pivotData.allTotal
        
        createCell = (cellType, className, textContent, attributes) ->
            th = document.createElement(cellType)
            if className then th.className = className
            if textContent isnt null and textContent isnt undefined then th.textContent = textContent
            if attributes then th.setAttribute(attr, val) for own attr, val of attributes
            return th

        processKeys = (keysArr, className) ->
            lastRow = keysArr.length - 1
            lastCol = keysArr[0].length - 1
            rMark = []
            headers = []
            th = createCell("th", className, keysArr[0][0])
            flatKey = keysArr[0][0]
            nodePos = 0
            node = {"node": nodePos, "row": 0, "col": 0, "th": th, "parent": null, "children": [], "descendants": lastCol, "leaves": 1, "flatKey": flatKey}
            headers[0] = node 
            rMark[0] = node
            c = 1
            while c <= lastCol
                th = createCell("th", className, keysArr[0][c])
                flatKey = flatKey + String.fromCharCode(0) + keysArr[0][c]
                ++nodePos
                node =  {"node": nodePos, "row": 0, "col": c, "th": th, "parent": rMark[c-1], "children": [], "descendants": lastCol-c, "leaves": 1, "flatKey": flatKey}
                rMark[c] = node
                rMark[c-1].children.push(node)
                ++c
            rMark[lastCol].leaves = 0
            r = 1
            while r <= lastRow
                repeats = true
                flatKey = ""
                c = 0
                while c <= lastCol
                    flatKey = if c is 0 then keysArr[r][c] else flatKey + String.fromCharCode(0) + keysArr[r][c]
                    if ((keysArr[r][c] is keysArr[rMark[c].row][c]) and (c isnt lastCol)  and (repeats))
                        repeats = true
                        ++c
                        continue
                    th = createCell("th", className, keysArr[r][c])
                    ++nodePos
                    header = {"node": nodePos, "row": r, "col": c, "th": th, "parent": null, "children": [], "descendants": 0, "leaves": 1, "flatKey": flatKey}
                    if c is 0
                        headers.push header
                    else
                        header.parent = rMark[c-1]
                        rMark[c-1].children.push header
                        x = 0
                        while x <= c-1
                            rMark[x].descendants = rMark[x].descendants + 1
                            ++x
                    rMark[c] = header
                    repeats = false
                    ++c
                c = 0
                while c <= lastCol
                    rMark[c].leaves = rMark[c].leaves + 1
                    ++c
                rMark[lastCol].leaves = 0
                ++r
            return headers

        buildColHeaderHeader = (thead, colHeaderHeaders, rowAttrs, colAttrs, tr, col) ->
            colAttr = colAttrs[col]
            th = createCell("th", "pvtAxisLabel", colAttr)
            textContent = colAttr
            if col < colAttrs.length-1
                textContent = " " + arrowExpanded + " " + colAttr
            th = createCell("th", "pvtAxisLabel", textContent)
            th.setAttribute("data-colAttr", colAttr)
            tr.appendChild th
            colHeaderHeaders.push({"tr": tr, "th": th, "clickStatus": "expanded"})
            thead.appendChild tr

        buildColHeaderHeaders = (thead, colHeaderHeaders, rowAttrs, colAttrs) ->
            tr = document.createElement("tr")
            if rowAttrs.length != 0
                tr.appendChild createCell("th", null, null, {"colspan": rowAttrs.length, "rowspan": colAttrs.length});
            buildColHeaderHeader thead, colHeaderHeaders, rowAttrs, colAttrs, tr, 0
            for c in [1..colAttrs.length] when c < colAttrs.length
                tr = document.createElement("tr")
                buildColHeaderHeader thead, colHeaderHeaders, rowAttrs, colAttrs, tr, c

        buildColHeaderHeadersClickEvents = (colHeaderHeaders, colHeaderCols, colAttrs) ->
            for i in [0..colAttrs.length-1] when i < colAttrs.length-1
                th = colHeaderHeaders[i].th
                colAttr = colAttrs[i]
                th.onclick = (event) ->
                    event = event || window.event
                    toggleColHeaderHeader colHeaderHeaders, colHeaderCols, colAttrs, event.target.getAttribute("data-colAttr")

        buildColHeaders = (colHeaderHeaders, colHeaderCols, colHeader, rowAttrs, colAttrs) ->
            # DF Recurse
            for h in colHeader.children
                buildColHeaders(colHeaderHeaders, colHeaderCols, h, rowAttrs, colAttrs)
            # Process
            tr = colHeaderHeaders[colHeader.col].tr
            th = colHeader.th
            th.setAttribute("data-colHeader", th.textContent) 
            if colHeader.col == colAttrs.length-1 and rowAttrs.length != 0
                th.setAttribute("rowspan", 2)
            if colHeader.children.length !=0
                th.setAttribute("colspan", colHeader.descendants+1)
            th.setAttribute("data-node", colHeaderCols.length)
            tr.appendChild(th)
            if colHeader.children.length !=0
                th.textContent = " " + arrowExpanded + " " + th.textContent
                th.onclick = (event) ->
                    event = event || window.event
                    toggleCol(colHeaderCols, parseInt(event.target.getAttribute("data-node")))
                rowspan = colAttrs.length-(colHeader.col+1) + if rowAttrs.length != 0 then 1 else 0
                style = "pvtColLabel col" + colHeader.row
                th = createCell("th", style, '', {"rowspan": rowspan})
                colHeader.children[0].tr.appendChild(th)
                colHeader.sTh = th
            colHeader.clickStatus = "expanded"
            colHeader.tr = tr
            colHeaderCols.push(colHeader)
        
        buildRowHeaderHeaders = (thead, rowHeaderHeaders, rowAttrs, colAttrs) ->
            tr = document.createElement("tr")
            rowHeaderHeaders.th = []
            for i, rowAttr of rowAttrs
                textContent = rowAttr
                if i < rowAttrs.length-1
                    textContent = " " + arrowExpanded + " " + rowAttr
                th = createCell("th", "pvtAxisLabel", textContent)
                th.setAttribute("data-rowAttr", rowAttr)
                tr.appendChild th                
                rowHeaderHeaders.th.push({"th": th, "clickStatus": "expanded"})
            if colAttrs.length != 0
                th = createCell("th")
                tr.appendChild th
            thead.appendChild tr
            rowHeaderHeaders.tr = tr

        buildRowHeaderHeadersClickEvents = (rowHeaderHeaders, rowHeaderRows, rowAttrs) ->
            for i in [0..rowAttrs.length-1] when i < rowAttrs.length-1
                th = rowHeaderHeaders.th[i]
                rowAttr = rowAttrs[i]
                th.th.onclick = (event) ->
                    event = event || window.event
                    toggleRowHeaderHeader rowHeaderHeaders, rowHeaderRows, rowAttrs, event.target.getAttribute("data-rowAttr")

        buildRowTotalsHeader = (tr, rowAttrs, colAttrs) ->
            rowspan = 1
            if colAttrs.length != 0
                rowspan = colAttrs.length + (if rowAttrs.length ==0 then 0 else 1)
            th = createCell("th", "pvtTotalLabel", opts.localeStrings.totals, {"rowspan": rowspan})
            tr.appendChild th

        buildRowHeaders = (tbody, rowHeaderRows, rowHeader, rowAttrs, colAttrs) ->
            tr = document.createElement("tr")
            th = rowHeader.th
            th.setAttribute("rowspan", rowHeader.descendants+1)
            th.setAttribute("data-rowHeader", th.textContent) 
            if rowHeader.col == rowAttrs.length-1 and colAttrs.length != 0
                th.setAttribute("colspan", 2)
            th.setAttribute("data-node", rowHeaderRows.length)
            tr.appendChild(th)
            if rowHeader.children.length != 0
                th.textContent = " " + arrowExpanded + " " + th.textContent
                th.onclick = (event) ->
                    event = event || window.event
                    toggleRow(rowHeaderRows, parseInt(event.target.getAttribute("data-node")))
                colspan = rowAttrs.length-(rowHeader.col+1) + if colAttrs.length != 0 then 1 else 0
                th = createCell("th", "pvtRowLabel", '', {"colspan": colspan})
                tr.appendChild(th)
            rowHeader.clickStatus = "expanded"
            rowHeader.tr = tr
            rowHeaderRows.push(rowHeader)
            tbody.appendChild(tr)
            for h in rowHeader.children
                buildRowHeaders(tbody, rowHeaderRows, h, rowAttrs, colAttrs)

        buildValues = (rowHeaderRows, colHeaderCols) ->
            for rowHeader in rowHeaderRows
                tr = rowHeader.tr
                flatRowKey = rowHeader.flatKey
                for colHeader in colHeaderCols
                    flatColKey = colHeader.flatKey
                    aggregator = tree[flatRowKey][flatColKey] ? {value: (-> null), format: -> ""}
                    val = aggregator.value()
                    style = "pvtVal"
                    style = if (colHeader.children.length != 0) then  style +  " pvtColSubtotal" else style
                    style = if (rowHeader.children.length != 0) then  style +  " pvtRowSubtotal" else style
                    style = style + " row"+rowHeader.row+" col"+colHeader.row+" rowcol"+rowHeader.col+" colcol"+colHeader.col
                    td = createCell("td", style, aggregator.format(val), {"data-value": val})
                    tr.appendChild td
                # buildRowTotal
                totalAggregator = rowTotals[flatRowKey]
                val = totalAggregator.value()
                td = createCell("td", "pvtTotal rowTotal", totalAggregator.format(val), {"data-value": val, "data-row": "row"+rowHeader.row, "data-col": "col"+rowHeader.col})
                tr.appendChild td

        buildColTotalsHeader = (rowAttrs, colAttrs) ->
            tr = document.createElement("tr")
            colspan = rowAttrs.length + (if colAttrs.length == 0 then 0 else 1)
            th = createCell("th", "pvtTotalLabel", opts.localeStrings.totals, {"colspan": colspan})
            tr.appendChild(th)
            return tr

        buildColTotals = (tr, colHeaderCols) ->
            for h in colHeaderCols
                totalAggregator = colTotals[h.flatKey]
                val = totalAggregator.value()
                style = "pvtVal pvtTotal colTotal"
                style = if h.children.length then style + " pvtColSubtotal" else style
                style = style + " col"+h.row+" colcol"+h.col
                td = createCell("td", style, totalAggregator.format(val), {"data-value": val, "data-for": "col"+h.col})
                tr.appendChild td

        buildGrandTotal = (result, tr) ->
            totalAggregator = allTotal
            val = totalAggregator.value()
            td = createCell("td", "pvtGrandTotal", totalAggregator.format(val), {"data-value": val})
            tr.appendChild td
            result.appendChild tr

        collapseCol = (colHeaderCols, c) ->
            if not colHeaderCols[c]
                return
            h = colHeaderCols[c]
            if h.clickStatus is "collapsed"
                return
            colspan = 0
            for i in [1..h.descendants] when h.descendants != 0
                d = colHeaderCols[c-i]
                if d.descendants != 0
                    d.th.textContent = " " + arrowCollapsed + " " + d.th.getAttribute("data-colHeader")
                d.clickStatus = "collapsed"
                d.th.setAttribute("colspan", 1)
                if d.th.style.display isnt "none"
                    ++colspan
                    d.th.style.display = "none"
                    if d.children.length
                        $('table.pvtTable tbody tr td.pvtColSubtotal.col' + d.row + '.colcol' + d.col).hide()
                    else
                        $('table.pvtTable tbody tr td.pvtVal.col' + d.row).not('.pvtColSubtotal').hide()
                    if d.sTh
                        d.sTh.style.display = "none"
            p = h.parent
            while p isnt null
                p.th.setAttribute("colspan", parseInt(p.th.getAttribute("colspan"))-colspan)
                p = p.parent
            if h.descendants != 0
                h.th.textContent = " " + arrowCollapsed + " " + h.th.getAttribute("data-colHeader")
            h.clickStatus = "collapsed"
            h.th.setAttribute("colspan", 1)
            h.th.style.display = ""

        expandCol = (colHeaderCols, c) ->
            if not colHeaderCols[c]
                return
            h = colHeaderCols[c]
            if h.clickStatus is "expanded"
                return
            colspan = 0
            for i in [1..h.descendants] when h.descendants != 0
                d = colHeaderCols[c-i]
                if d.descendants != 0
                    d.th.textContent = " " + arrowCollapsed + " " + d.th.getAttribute("data-colHeader")
                d.clickStatus = "collapsed"
                d.th.setAttribute("colspan", 1)
                if d.th.style.display isnt "none"
                    ++colspan
                    d.th.style.display = "none"
                    if d.children.length
                        $('table.pvtTable tbody tr td.pvtColSubtotal.col' + d.row + '.colcol' + d.col).hide()
                    else
                        $('table.pvtTable tbody tr td.pvtVal.col' + d.row).not('.pvtColSubtotal').hide()
                    if d.sTh
                        d.sTh.style.display = "none"
            for ch in h.children
                if ch.th.style.display is "none"
                    ++colspan
                    ch.th.style.display = ""
                    if ch.children.length
                        $('table.pvtTable tbody tr td.pvtColSubtotal.col' + ch.row + '.colcol' + ch.col).show()
                    else
                        $('table.pvtTable tbody tr td.pvtVal.col' + ch.row).not('.pvtColSubtotal').show()
                    if ch.sTh
                        ch.sTh.style.display = ""
            h.th.setAttribute("colspan", h.children.length+1)
            if h.descendants != 0
                h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute("data-colHeader")
            h.clickStatus = "expanded"
            h.th.style.display = ""
            if h.sTh
                h.sTh.style.display = ""
            p = h.parent
            while p isnt null
                p.th.setAttribute("colspan", (colspan + parseInt(p.th.getAttribute("colspan"))))
                p = p.parent

        collapseRow = (rowHeaderRows, r) ->
            if not rowHeaderRows[r]
                return
            h = rowHeaderRows[r]
            if h.clickStatus is "collapsed"
                return
            rowspan = 0
            for i in [1..h.descendants] when h.descendants != 0
                d = rowHeaderRows[r+i]
                if d.descendants != 0
                    d.th.textContent = " " + arrowCollapsed + " " + d.th.getAttribute("data-rowHeader")
                d.clickStatus = "collapsed"
                d.th.setAttribute("rowspan", 1)
                if d.tr.style.display isnt "none"
                    ++rowspan
                    d.tr.style.display = "none"
            p = h.parent
            while p isnt null
                p.th.setAttribute("rowspan", parseInt(p.th.getAttribute("rowspan"))-rowspan)
                p = p.parent
            if h.descendants != 0
                h.th.textContent = " " + arrowCollapsed + " " + h.th.getAttribute("data-rowHeader")
            h.clickStatus = "collapsed"
            h.th.setAttribute("rowspan", 1)
            h.tr.style.display = ""

        expandRow = (rowHeaderRows, r) ->
            if not rowHeaderRows[r]
                return
            h = rowHeaderRows[r]
            if h.clickStatus is "expanded"
                return
            rowspan = 0
            for i in [1..h.descendants] when h.descendants != 0
                d = rowHeaderRows[r+i]
                if d.descendants != 0
                    d.th.textContent = " " + arrowCollapsed + " " + d.th.getAttribute("data-rowHeader")
                d.clickStatus = "collapsed"
                d.th.setAttribute("rowspan", 1)
                if d.tr.style.display isnt "none"
                    --rowspan
                    d.tr.style.display = "none"
            for c in h.children
                if c.tr.style.display is "none"
                    ++rowspan
                    c.tr.style.display = ""
            h.th.setAttribute("rowspan", h.children.length+1)
            if h.descendants != 0
                h.th.textContent = " " + arrowExpanded + " " + h.th.getAttribute("data-rowHeader")
            h.clickStatus = "expanded"
            h.tr.style.display = ""
            p = h.parent
            while p isnt null
                p.th.setAttribute("rowspan", (rowspan + parseInt(p.th.getAttribute("rowspan"))))
                p = p.parent

        toggleCol = (colHeaderCols, c) ->
            if not colHeaderCols[c]
                return
            if colHeaderCols[c].clickStatus is "collapsed"
                expandCol(colHeaderCols, c)
            else
                collapseCol(colHeaderCols, c)

        toggleRow = (rowHeaderRows, r) ->
            if not rowHeaderRows[r]
                return
            if rowHeaderRows[r].clickStatus is "collapsed"
                expandRow(rowHeaderRows, r)
            else
                collapseRow(rowHeaderRows, r)

        collapseRowsAt = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            idx = rowAttrs.indexOf(rowAttr)
            if idx < 0 or idx == rowAttrs.length-1
                return
            i = idx
            nAttrs = rowAttrs.length-1
            while i < nAttrs
                th = rowHeaderHeaders.th[i]
                th.th.textContent = " " + arrowCollapsed + " " + rowAttrs[i]
                th.clickStatus = "collapsed"
                ++i          
            i = 0
            nRows = rowHeaderRows.length
            while i < nRows
                h = rowHeaderRows[i]
                if h.col is idx
                    collapseRow(rowHeaderRows, h.node)
                    i = i + h.descendants + 1
                else
                    ++i

        expandRowsAt = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            idx = rowAttrs.indexOf(rowAttr)
            if idx < 0 or idx == rowAttrs.length-1
                return
            for i in [0..idx]
                th = rowHeaderHeaders.th[i]
                th.th.textContent = " " + arrowExpanded + " " + rowAttrs[i]
                th.clickStatus = "expanded"
                j = 0
                nRows = rowHeaderRows.length
                while j < nRows
                    h = rowHeaderRows[j]
                    if h.col == i
                        expandRow(rowHeaderRows, h.node)
                        j = j + h.descendants + 1
                    else
                        ++j

        collapseColsAt = (colHeaderHeaders, colHeaderCols, colAttrs, colAttr) ->
            idx = colAttrs.indexOf(colAttr)
            if idx < 0 or idx == colAttrs.length-1
                return
            i = idx
            nAttrs = colAttrs.length-1
            while i < nAttrs
                th = colHeaderHeaders[i].th
                th.textContent = " " + arrowCollapsed + " " + colAttrs[i]
                th.clickStatus = "collapsed"
                ++i          
            i = 0
            nCols = colHeaderCols.length
            while i < nCols
                h = colHeaderCols[i]
                if h.col is idx
                    collapseCol(colHeaderCols, i)
                ++i

        expandColsAt = (colHeaderHeaders, colHeaderCols, colAttrs, colAttr) ->
            idx = colAttrs.indexOf(colAttr)
            if idx < 0 or idx == colAttrs.length-1
                return
            for i in [0..idx]
                th = colHeaderHeaders[i].th
                th.textContent = " " + arrowExpanded + " " + colAttrs[i]
                th.clickStatus = "expanded"
                j = 0
                nCols = colHeaderCols.length
                while j < nCols
                    h = colHeaderCols[j]
                    if h.col == i
                        expandCol(colHeaderCols, j)
                    ++j

        toggleColHeaderHeader = (colHeaderHeaders, colHeaderCols, colAttrs, colAttr) ->
            idx = colAttrs.indexOf(colAttr)
            th = colHeaderHeaders[idx].th
            if th.clickStatus is "collapsed"
                expandColsAt colHeaderHeaders, colHeaderCols, colAttrs, colAttr
            else
                collapseColsAt colHeaderHeaders, colHeaderCols, colAttrs, colAttr


        toggleRowHeaderHeader = (rowHeaderHeaders, rowHeaderRows, rowAttrs, rowAttr) ->
            idx = rowAttrs.indexOf(rowAttr)
            th = rowHeaderHeaders.th[idx]
            if th.clickStatus is "collapsed"
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

            if rowAttrs.length != 0
                rowHeaders = processKeys(rowKeys, "pvtRowLabel")
            if colAttrs.length != 0
                colHeaders = processKeys(colKeys, "pvtColLabel")
            result = document.createElement("table")
            result.className = "pvtTable"
            result.style.display = "none"
            thead = document.createElement("thead")
            result.appendChild thead
            if colAttrs.length != 0
                buildColHeaderHeaders(thead, colHeaderHeaders, rowAttrs, colAttrs)
                for h in colHeaders
                   buildColHeaders colHeaderHeaders, colHeaderCols, h, rowAttrs, colAttrs
                buildColHeaderHeadersClickEvents colHeaderHeaders, colHeaderCols, colAttrs
            if rowAttrs.length != 0
                buildRowHeaderHeaders(thead, rowHeaderHeaders, rowAttrs, colAttrs)
                if colAttrs.length == 0
                    buildRowTotalsHeader(rowHeaderHeaders.tr, rowAttrs, colAttrs)
            if colAttrs.length != 0
                buildRowTotalsHeader(colHeaderHeaders[0].tr, rowAttrs, colAttrs)
            tbody = document.createElement("tbody")
            result.appendChild tbody
            if rowAttrs.length != 0
                for h in rowHeaders
                    buildRowHeaders tbody, rowHeaderRows, h, rowAttrs, colAttrs
                buildRowHeaderHeadersClickEvents rowHeaderHeaders, rowHeaderRows, rowAttrs
            buildValues(rowHeaderRows, colHeaderCols)
            tr = buildColTotalsHeader(rowAttrs, colAttrs)
            if colAttrs.length != 0
                buildColTotals(tr, colHeaderCols)
            buildGrandTotal(tbody, tr)
            result.setAttribute("data-numrows", rowKeys.length)
            result.setAttribute("data-numcols", colKeys.length)
            if not opts.collapseRowsAt and not opts.collapseColsAt
                result.style.display = ""
            if opts.collapseRowsAt
                setTimeout (->
                    collapseRowsAt rowHeaderHeaders, rowHeaderRows, rowAttrs, opts.collapseRowsAt
                    if not opts.collapseColsAt
                        result.style.display = ""
                ), 0
            if opts.collapseColsAt
                setTimeout (->
                    collapseColsAt colHeaderHeaders, colHeaderCols, colAttrs, opts.collapseColsAt
                    result.style.display = ""
                ), 0
            return result

        return main(rowAttrs, rowKeys, colAttrs, colKeys)
        
    $.pivotUtilities.subtotal_renderers =
        "Table With Subtotal":  (pvtData, opts) -> SubtotalRenderer(pvtData, opts)
        "Table With Subtotal Bar Chart":   (pvtData, opts) -> $(SubtotalRenderer(pvtData, opts)).barchart()
        "Table With Subtotal Heatmap":   (pvtData, opts) -> $(SubtotalRenderer(pvtData, opts)).heatmap()
        "Table With Subtotal Row Heatmap":   (pvtData, opts) -> $(SubtotalRenderer(pvtData, opts)).heatmap("rowheatmap")
        "Table With Subtotal Col Heatmap":  (pvtData, opts) -> $(SubtotalRenderer(pvtData, opts)).heatmap("colheatmap")
