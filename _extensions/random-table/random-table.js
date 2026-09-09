function getRows(table) {
	return Array.from(table.tBodies).flatMap((body) => Array.from(body.rows))
}

function makeResultTable(table, row) {
	const result = table.cloneNode(false)

	result.removeAttribute('id')

	if (table.tHead) { result.append(table.tHead.cloneNode(true)) }

	const body = document.createElement('tbody')

	body.append(row.cloneNode(true))
	result.append(body)

	return result
}

function initRandomTable(root) {
	const table = root.querySelector('details table')
	const button = root.querySelector('.random-table-roll')
	const output = root.querySelector('.random-table-result')

	if (!table || !button || !output) { return }

	const rows = getRows(table)

	if (rows.length === 0) {
		return
	}

	button.hidden = false

	button.addEventListener('click', () => {
		const index = Math.floor(Math.random() * rows.length)
		const row = rows[index]

		output.replaceChildren(makeResultTable(table, row))
	})
}

function initRandomTables() {
	for (const root of document.querySelectorAll('.random-table')) { initRandomTable(root) }
}

if (document.readyState === 'loading') {
	document.addEventListener('DOMContentLoaded', initRandomTables)
} else {
	initRandomTables()
}
