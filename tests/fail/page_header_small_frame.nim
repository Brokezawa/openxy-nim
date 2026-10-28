import openxy

var state: PageHeader
var frame: Frame[2, 64, 10, 4, 16]
var titles: array[8, string]
var values: array[8, HeaderText]
pageHeader(state, Input(), frame, titles, values, 2)
