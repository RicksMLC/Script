// psLib.ks Print Status Library

function InitPrintStatus {
	set Terminal:width to 100.
	global psMaxRow to 0.
	global psCol to 50.
	global psWidth to Terminal:width - psCol.
	global psLines is List("").
}

InitPrintStatus().

function PrintLines {
	local n is 0.
	for s in psLines {
		print s at(psCol, n).
		set n to n + 1.
	}
}

function PSClearPrevStats {
	from {local n is psMaxRow.} until n = 0 step {set n to n - 1.} do {
		print "|":PadRight(psWidth) at(psCol, n).
	}
	set psMaxRow to 0.
}

function PSPrintRow {
	parameter row.
	parameter ps.
	print ps:PadRight(psWidth) at(psCol, row).
	if row > psMaxRow { set psMaxRow to row. }
}

function PrintStatus {
	parameter row.
	parameter name.
	parameter data is "".
	parameter clearPrevStats to false.
	if clearPrevStats {
		PSClearPrevStats().
	}
	set ps to "| " + name + ": " + data.
	PSPrintRow(row, ps).
}

function PrintPairStatus {
	parameter row.
	parameter name.
	parameter data.
	parameter name2.
	parameter data2 is "".
	parameter fixFirstWidth is 0.
	parameter clearPrevStats to false.
	if clearPrevStats {
		PSClearPrevStats().
	}
	set ps to ("| " + name + ": " + data + " "):PadRight(fixFirstWidth) + name2 + ": " + data2.
	PSPrintRow(row, ps).
}

function PrintMultiStatus {
	parameter row.
	parameter name.
	parameter data.
	parameter name2.
	parameter data2 is "".
	parameter name3 is "".
	parameter data3 is "".
	parameter fixFirstWidth is 0.
	parameter clearPrevStats to false.
	if clearPrevStats {
		PSClearPrevStats().
	}
	set ps to ("| " + name + ": " + data + " "):PadRight(fixFirstWidth) + name2 + ": " + data2.
	if name3 <> "" {
		set ps to ps + " " + name3 + ": " + data3.
	}
	PSPrintRow(row, ps).
}

