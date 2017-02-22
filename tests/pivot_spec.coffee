fixtureData = [
    ["name",    "gender",   "colour",       "birthday",     "trials",   "successes"],
    ["Nick",    "male",     "blue",         "1982-11-07",   103,        12],
    ["Jane",    "female",   "red",          "1982-11-08",   95,         25],
    ["John",    "male",     "blue",         "1982-12-08",   112,        30],
    ["Carol",   "female",   "yellow",       "1983-11-11",   102,        14],
    ["Raj",     "male",     "blue",         "1982-11-07",   103,        12],
    ["Rani",    "female",   "red",          "1982-11-08",   95,         25],
    ["Joshi",   "male",     "blue",         "1982-12-09",   112,        12],
    ["Vel",     "male",     "yellow",       "1982-12-01",   112,        25],
    ["Sai",     "male",     "red",          "1982-11-08",   112,        30],
    ["Geeth",   "female",   "blue",         "1982-12-03",   112,        14],
    ["Malar",   "male",     "red",          "1982-11-05",   112,        12],
    ["Nila",    "male",     "blue",         "1982-12-07",   112,        25],
    ["Yaazhi",  "male",     "yellow",       "1982-12-06",   112,        30],
    ["Mukhi",   "male",     "yellow",       "1982-11-07",   112,        14]]

fixtureData2 = [
    ["name",    "gender",   "colour",    "birthday",     "trials",   "successes"],
    ["Nick",    "male",     "blue",      "1982-11-07",   103,        12],
    ["Jane",    "female",   "red",       "1982-11-08",   95,         25],
    ["John",    "male",     "blue",      "1982-12-08",   112,        30],
    ["Carol",   "female",   "yellow",    "1983-12-08",   102,        14]]


describe "$.pivotUI()", ->
    describe "with no rows/cols, default count aggregator, subtotal renderer",  ->
        table = null

        beforeEach (done) ->
            table = $("<div>").pivotUI fixtureData, {
                dataClass: $.pivotUtilities.SubtotalPivotData,
                renderers: $.pivotUtilities.subtotal_renderers,
                onRefresh: done
            }


        it "has all the basic UI elements", (done) ->
            expect table.find("td.pvtAxisContainer").length
            .toBe   3
            expect table.find("td.pvtRendererArea").length
            .toBe   1
            expect table.find("td.pvtVals").length
            .toBe   1
            expect table.find("select.pvtRenderer").length
            .toBe   1
            expect table.find("select.pvtAggregator").length
            .toBe   1
            expect table.find("span.pvtAttr").length
            .toBe   6
            expect table.find("th.pvtTotalLabel").length
            .toBe   1 
            expect table.find("td.pvtGrandTotal").length
            .toBe   1 
            done()

        it "reflects its inputs", (done) ->
            expect table.find("td.pvtUnused span.pvtAttr").length
            .toBe  6
            expect table.find("select.pvtRenderer").val()
            .toBe  "Table With Subtotal"
            expect table.find("select.pvtAggregator").val()
            .toBe  "Count"
            done()

        it "renders a table", (done) ->
            expect table.find("table.pvtTable").length
            .toBe  1 
            done()

        describe "its renderer output", ->
            it "has the correct type and number of cells", (done) ->
                expect table.find("th.pvtTotalLabel").length
                .toBe  1 
                expect table.find("td.pvtGrandTotal").length
                .toBe  1 
                done()

            it "has the correct textual representation", (done) ->
                expect table.find("table.pvtTable").text()
                .toBe ["Totals", "14"].join("")
                done()

            it "has a correct grand total with data value", (done) ->
                expect table.find("td.pvtGrandTotal").text()
                .toBe  "14"
                expect table.find("td.pvtGrandTotal").data("value")
                .toBe  14
                done()

    describe "with collapsed rows and cols, subtotal_aggregators",  ->
        table = null

        beforeEach (done) ->
            table = $("<div>").pivotUI fixtureData, 
                dataClass: $.pivotUtilities.SubtotalPivotData,
                rows: ["gender", "colour"],
                cols: ["birthday", "trials"],
                aggregators: $.pivotUtilities.subtotal_aggregators,
                vals: ["successes"],
                renderers: $.pivotUtilities.subtotal_renderers,
                rendererOptions: {
                    collapseColsAt: 0,
                    collapseRowsAt: 0
                },
                onRefresh: done

        it "has all the basic UI elements", (done) ->
            expect table.find("td.pvtAxisContainer").length
            .toBe  3
            expect table.find("td.pvtRendererArea").length
            .toBe  1
            expect table.find("td.pvtVals").length
            .toBe  1
            expect table.find("select.pvtRenderer").length
            .toBe  1
            expect table.find("select.pvtAggregator").length
            .toBe  1
            expect table.find("span.pvtAttr").length
            .toBe  6
            done()

        it "reflects its inputs", (done) ->
            expect table.find("td.pvtUnused span.pvtAttr").length
            .toBe  2 
            expect table.find("td.pvtRows span.pvtAttr").length
            .toBe  2 
            expect table.find("td.pvtCols span.pvtAttr").length
            .toBe  2 
            expect table.find("select.pvtRenderer").val()
            .toBe  "Table With Subtotal"
            expect table.find("select.pvtAggregator").val()
            .toBe  "Sum As Fraction Of Parent Row"
            done()

        it "renders a table", (done) ->
            expect table.find("table.pvtTable").length
            .toBe  1 
            done()

        describe "its renderer output", ->
            it "has the correct type and number of cells", (done) ->
                expect table.find("th.pvtAxisLabel").length
                .toBe  4 
                expect table.find("th.pvtAxisLabel.collapsed").length
                .toBe  2 
                expect table.find("th.pvtRowLabel.rowcollapsed").length
                .toBe  4 
                expect table.find("th.pvtColLabel.colcollapsed").length
                .toBe  20 
                expect table.find("th.pvtTotalLabel.rowTotal").length
                .toBe  1 
                expect table.find("th.pvtTotalLabel.colTotal").length
                .toBe  1 
                expect table.find("td.pvtVal.pvtColSubtotal.pvtRowSubtotal").length
                .toBe  20 
                expect table.find("td.pvtTotal.rowTotal.pvtRowSubtotal").length
                .toBe  2 
                expect table.find("td.pvtTotal.colTotal.pvtColSubtotal").length
                .toBe  10 
                expect table.find("td.pvtGrandTotal").length
                .toBe  1 
                done()

            it "has the correct textual representation", (done) ->
                expect table.find("th.pvtColLabel").text()
                .toBe " \u25B6 1982-11-05 \u25B6 1982-11-07 \u25B6 1982-11-08 \u25B6 1982-12-01 \u25B6 1982-12-03 \u25B6 1982-12-06 \u25B6 1982-12-07 \u25B6 1982-12-08 \u25B6 1982-12-09 \u25B6 1983-11-1111210311295112112112112112112112102"
                expect table.find("th.pvtRowLabel").text()
                .toBe " \u25B6 femaleblueredyellow \u25B6 maleblueredyellow"
                done()

            it "has a correct spot-checked cell with data value", (done) ->
                expect table.find("td.pvtVal.pvtRowSubtotal.row0.col3.rowcol0.colcol1").text()
                .toBe  "17.9%"
                expect table.find("td.pvtVal.pvtTotal.colTotal.pvtColSubtotal.col3.colcol0").data("value")
                .toBe  (50+30)/280
                done()

    describe "with row and col subtotal hidden on expand",  ->
        table = null

        beforeEach (done) ->
            table = $("<div>").pivotUI fixtureData, 
                dataClass: $.pivotUtilities.SubtotalPivotData,
                rows: ["colour", "birthday", "name"],
                cols: ["trials", "gender", "successes"],
                aggregators: $.pivotUtilities.subtotal_aggregators,
                vals: ["successes"],
                renderers: $.pivotUtilities.subtotal_renderers,
                rendererOptions: {
                    rowSubtotalDisplay: {
                        hideOnExpand: true
                    },
                    colSubtotalDisplay: {
                        hideOnExpand: true
                    }
                },
                onRefresh: done

        it "has all the basic UI elements", (done) ->
            expect table.find("td.pvtAxisContainer").length
            .toBe  3
            expect table.find("td.pvtRendererArea").length
            .toBe  1
            expect table.find("td.pvtVals").length
            .toBe  1
            expect table.find("select.pvtRenderer").length
            .toBe  1
            expect table.find("select.pvtAggregator").length
            .toBe  1
            expect table.find("span.pvtAttr").length
            .toBe  6
            done()

        it "reflects its inputs", (done) ->
            expect table.find("td.pvtUnused span.pvtAttr").length
            .toBe  0 
            expect table.find("td.pvtRows span.pvtAttr").length
            .toBe  3 
            expect table.find("td.pvtCols span.pvtAttr").length
            .toBe  3 
            expect table.find("select.pvtRenderer").val()
            .toBe  "Table With Subtotal"
            expect table.find("select.pvtAggregator").val()
            .toBe  "Sum As Fraction Of Parent Row"
            done()

        it "renders a table", (done) ->
            expect table.find("table.pvtTable").length
            .toBe  1 
            done()

        describe "its renderer output", ->
            it "has the correct type and number of cells", (done) ->
                expect table.find("th.pvtAxisLabel").length
                .toBe  6 
                expect table.find("th.pvtAxisLabel.collapsed").length
                .toBe  0 
                expect table.find("th.pvtRowLabel.rowshow.rowcollapsed").length
                .toBe  0 
                expect table.find("th.pvtColLabel.colshow.colcollapsed").length
                .toBe  0 
                expect table.find("th.pvtRowLabel.rowshow.rowexpanded").length
                .toBe  14 
                expect table.find("th.pvtColLabel.colshow.colexpanded").length
                .toBe  9 
                expect table.find("th.pvtRowSubtotal.rowhide.rowexpanded").length
                .toBe  14 
                expect table.find("th.pvtColSubtotal.colhide.colexpanded").length
                .toBe  9 
                expect table.find("td.pvtColSubtotal.pvtRowSubtotal.colhide.colexpanded.rowhide.rowexpanded").length
                .toBe  9*14 
                expect table.find("th.pvtTotalLabel.rowTotal").length
                .toBe  1 
                expect table.find("th.pvtTotalLabel.colTotal").length
                .toBe  1 
                expect table.find("td.pvtTotal.rowTotal.pvtRowSubtotal").length
                .toBe  14 
                expect table.find("td.pvtTotal.colTotal.pvtColSubtotal").length
                .toBe  9 
                expect table.find("td.pvtGrandTotal").length
                .toBe  1 
                done()

            it "has the correct textual representation", (done) ->
                expect table.find("th.pvtColLabel").text()
                .toBe " \u25E2 95 \u25E2 102 \u25E2 103 \u25E2 112 \u25E2 female \u25E2 female \u25E2 male \u25E2 female \u25E2 male2514121412142530"
                expect table.find("th.pvtRowLabel").text()
                .toBe " \u25E2 blue \u25E2 1982-11-07NickRaj \u25E2 1982-12-03Geeth \u25E2 1982-12-07Nila \u25E2 1982-12-08John \u25E2 1982-12-09Joshi \u25E2 red \u25E2 1982-11-05Malar \u25E2 1982-11-08JaneRaniSai \u25E2 yellow \u25E2 1982-11-07Mukhi \u25E2 1982-12-01Vel \u25E2 1982-12-06Yaazhi \u25E2 1983-11-11Carol"
                done()

            it "has a correct spot-checked cell with data value", (done) ->
                expect table.find("td.pvtVal.rowshow.colshow.row10.col5.rowcol2.colcol2").text()
                .toBe  "100.0%"
                expect table.find("td.pvtVal[data-rownode=\"3\"][data-colnode=\"6\"]").text()
                .toBe  "50.0%"
                done()

describe "$.pivot()", ->
    describe "with no rows/cols, default count aggregator, subtotal renderer",  ->
        table = $("<div>").pivot fixtureData, {
            dataClass: $.pivotUtilities.SubtotalPivotData,
            renderer: $.pivotUtilities.subtotal_renderers["Table With Subtotal"]
        }

        it "has all the basic UI elements", ->
            expect table.find("th.pvtTotalLabel").length
            .toBe   1 
            expect table.find("td.pvtGrandTotal").length
            .toBe   1 

        it "renders a table", ->
            expect table.find("table.pvtTable").length
            .toBe  1 

        describe "its renderer output", ->
            it "has the correct type and number of cells", ->
                expect table.find("th.pvtTotalLabel").length
                .toBe  1 
                expect table.find("td.pvtGrandTotal").length
                .toBe  1 

            it "has the correct textual representation", ->
                expect table.find("table.pvtTable").text()
                .toBe ["Totals", "14"].join("")

            it "has a correct grand total with data value", ->
                expect table.find("td.pvtGrandTotal").text()
                .toBe  "14"
                expect table.find("td.pvtGrandTotal").data("value")
                .toBe  14

    describe "with rows/cols, subtotal_aggregator",  ->
        table = $("<div>").pivot fixtureData, 
            dataClass: $.pivotUtilities.SubtotalPivotData,
            rows: ["gender", "colour"],
            cols: ["birthday", "trials"],
            aggregator: $.pivotUtilities.subtotal_aggregators["Sum As Fraction Of Parent Column"](["successes"]),
            renderer: $.pivotUtilities.subtotal_renderers["Table With Subtotal"]

        it "renders a table", ->
            expect table.find("table.pvtTable").length
            .toBe  1 

        describe "its renderer output", ->
            it "has the correct type and number of cells", ->
                expect table.find("th.pvtAxisLabel").length
                .toBe  4 
                expect table.find("th.collapsed").length
                .toBe  0 
                expect table.find("th.expanded, th.rowexpanded, th.colexpanded").length
                .toBe  2+4+20 
                expect table.find("th.pvtAxisLabel.expanded").length
                .toBe  2 
                expect table.find("th.pvtRowLabel.rowexpanded").length
                .toBe  4 
                expect table.find("th.pvtColLabel.colexpanded").length
                .toBe  20 
                expect table.find("th.pvtTotalLabel.rowTotal").length
                .toBe  1 
                expect table.find("th.pvtTotalLabel.colTotal").length
                .toBe  1 
                expect table.find("td.pvtVal.pvtColSubtotal.pvtRowSubtotal").length
                .toBe  20 
                expect table.find("td.pvtTotal.rowTotal.pvtRowSubtotal").length
                .toBe  2 
                expect table.find("td.pvtTotal.colTotal.pvtColSubtotal").length
                .toBe  10 
                expect table.find("td.pvtGrandTotal").length
                .toBe  1 

            it "has the correct textual representation", ->
                expect table.find("th.pvtColLabel").text()
                .toBe " \u25E2 1982-11-05 \u25E2 1982-11-07 \u25E2 1982-11-08 \u25E2 1982-12-01 \u25E2 1982-12-03 \u25E2 1982-12-06 \u25E2 1982-12-07 \u25E2 1982-12-08 \u25E2 1982-12-09 \u25E2 1983-11-1111210311295112112112112112112112102"
                expect table.find("th.pvtRowLabel").text()
                .toBe " \u25E2 femaleblueredyellow \u25E2 maleblueredyellow"

            it "has a correct spot-checked cell with data value", ->
                expect table.find("td.pvtVal.pvtTotal.colTotal.col3.colcol1").text()
                .toBe  "62.5%"
                expect table.find("td.pvtVal.pvtTotal.colTotal.col4.colcol1").data("value")
                .toBe  30/80

describe "$.pivotUtilities", ->

    describe ".SubtotalPivotData()", ->
        sumOverSumOpts = 
            rows: [], cols: []
            aggregator: $.pivotUtilities.aggregators["Sum over Sum"](["a","b"])
            filter: -> true
            sorters: ->

        describe "with array-of-array input", ->
            aoaInput =  [ ["a","b"], [1,2], [3,4] ]
            pd = new $.pivotUtilities.SubtotalPivotData aoaInput, sumOverSumOpts

            it "has the correct grand total value", ->
                expect pd.getAggregator([],[]).value()
                .toBe (1+3)/(2+4)

        describe "with array-of-object input", ->
            aosInput =  [ {a:1, b:2}, {a:3, b:4} ]
            pd = new $.pivotUtilities.SubtotalPivotData aosInput, sumOverSumOpts

            it "has the correct grand total value", ->
                expect pd.getAggregator([],[]).value()
                .toBe (1+3)/(2+4)

        describe "with function input", ->
            functionInput = (record) ->
                record a:1, b:2
                record a:3, b:4
            pd = new $.pivotUtilities.SubtotalPivotData functionInput, sumOverSumOpts

            it "has the correct grand total value", ->
                expect pd.getAggregator([],[]).value()
                .toBe (1+3)/(2+4)

        describe "with jQuery table element input", ->
            tableInput = $ """
                <table>
                    <thead> 
                        <tr> <th>a</th><th>b</th> </tr>
                    </thead> 
                    <tbody>
                        <tr> <td>1</td> <td>2</td> </tr>
                        <tr> <td>3</td> <td>4</td> </tr>
                    </tbody>
                </table>
                """

            pd = new $.pivotUtilities.SubtotalPivotData tableInput, sumOverSumOpts

            it "has the correct grand total value", ->
                expect pd.getAggregator([],[]).value()
                .toBe (1+3)/(2+4)


        describe "with rows/cols, no filters/sorters, count aggregator", ->
            pd = new $.pivotUtilities.SubtotalPivotData fixtureData2, 
                rows: ["name", "colour"], 
                cols: ["trials", "successes"],
                aggregator: $.pivotUtilities.aggregators["Count"](),
                filter: -> true
                sorters: ->

            it "has correctly-ordered row keys", ->
                expect pd.getRowKeys()
                .toEqual [ [ 'Carol', 'yellow' ], [ 'Jane', 'red' ], [ 'John', 'blue' ], [ 'Nick', 'blue' ] ]
               
            it "has correctly-ordered col keys", ->
                expect pd.getColKeys()
                .toEqual [ [ 95, 25 ], [ 102, 14 ], [ 103, 12 ], [ 112, 30 ] ]

            it "can be iterated over", ->
                numNotNull = 0
                numNull = 0
                for r in pd.getRowKeys()
                    for c in pd.getColKeys()
                        if pd.getAggregator(r, c).value()?
                            numNotNull++ 
                        else
                            numNull++
                expect numNotNull
                .toBe 4
                expect numNull
                .toBe 12

            it "has a correct spot-checked aggregator", ->
                spots = [ {spot: [['Carol', 'yellow'], [102, 14]], val: 1}, {spot:  [['Jane', 'red'], [95, 25]], val: 1}, {spot: [['John', 'blue'], [112, 30]], val: 1}, {spot: [['Nick', 'blue'], [103, 12]], val: 1} ]
                for s in spots
                    agg = pd.getAggregator(s.spot[0],s.spot[1])
                    val = agg.value()
                    expect(val).toBe 1 
                    expect(agg.format(val)).toBe "" + s.val

            it "has correct spot-checked aggregators for subtotal-rows and subtotal-columns", ->
                spots = [ {spot: [['Carol'], [102]], val: 1}, {spot:  [['Jane'], [95]], val: 1}, {spot: [['John'], [112]], val: 1}, {spot: [['Nick'], [103]], val: 1} ]
                for s in spots
                    agg = pd.getAggregator(s.spot[0], s.spot[1])
                    val = agg.value()
                    expect(val).toBe s.val 
                    expect(agg.format(val)).toBe "" + s.val

            it "has correct row-total for subtotal-rows", ->
                for hdr in ['Carol', 'Jane', 'John', 'Nick']
                    agg = pd.getAggregator([hdr],[])
                    val = agg.value()
                    expect(val).toBe 1
                    expect(agg.format(val)).toBe "1"

            it "has correct column-total for subtotal-columns", ->
                for hdr in [95, 102, 103, 112]
                    agg = pd.getAggregator([],[hdr])
                    val = agg.value()
                    expect(val).toBe 1
                    expect(agg.format(val)).toBe "1"

            it "has a correct grand total aggregator", ->
                agg = pd.getAggregator([],[])
                val = agg.value()
                expect(val).toBe 4 
                expect(agg.format(val)).toBe "4"
