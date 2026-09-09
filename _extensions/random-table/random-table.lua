local dependency_added = false
local table_index = 0

local function cell(value)
	local content = pandoc.utils.type(value) == 'Inlines'
		and value
		or pandoc.Inlines({ pandoc.Str(pandoc.utils.stringify(value)) })

	return pandoc.Cell({ pandoc.Plain(content) })
end

local function make_table(config)
	local columns = config.columns
	local rows = config.rows or pandoc.List()

	if not columns or #columns == 0 then
		error('random-table: columns must be a non-empty list', 0)
	end

	local colspecs = {}
	local headers = {}
	local body = {}

	for _, column in ipairs(columns) do
		colspecs[#colspecs + 1] = { pandoc.AlignDefault }
		headers[#headers + 1] = cell(column)
	end

	for i, row in ipairs(rows) do
		if #row ~= #columns then
			error('random-table: row ' .. i .. ' has ' .. #row .. ' cells; expected ' .. #columns, 0)
		end

		local cells = {}

		for _, value in ipairs(row) do
			cells[#cells + 1] = cell(value)
		end

		body[#body + 1] = pandoc.Row(cells)
	end

	return pandoc.Table(
		pandoc.Caption(),
		colspecs,
		pandoc.TableHead({ pandoc.Row(headers) }),
		{ pandoc.TableBody(body) },
		pandoc.TableFoot()
	)
end

local function add_dependency()
	if dependency_added then
		return
	end

	quarto.doc.add_html_dependency({
		name = 'random-table',
		version = '0.2.0',
		scripts = {
			{ path = 'random-table.js', afterBody = true }
		},
		stylesheets = { 'random-table.css' }
	})

	dependency_added = true
end

function CodeBlock(el)
	if not el.classes:includes('random-table') then
		return
	end

	local ok, doc = pcall(
		pandoc.read,
		'---\n' .. el.text .. '\n---',
		'markdown'
	)

	if not ok then
		error('random-table: invalid YAML: ' .. tostring(doc), 0)
	end

	local config = doc.meta
	local table = make_table(config)

	if not quarto.doc.is_format('html') then
		return table
	end

	add_dependency()

	table_index = table_index + 1

	local caption = config.caption and pandoc.utils.stringify(config.caption) or nil
	local id = 'random-table-' .. pandoc.structure.unique_identifier(pandoc.Inlines(caption))
	local link_svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M7.95 21q-2.05 0-3.5-1.45T3 16.05q0-1 .375-1.9t1.075-1.6l2.625-2.625q.3-.3.713-.3t.712.3t.3.7t-.3.7l-2.65 2.65q-.425.425-.637.963T5 16.05q0 1.225.863 2.088T7.95 19q.575 0 1.125-.213t.975-.637l2.625-2.65q.3-.275.7-.275t.7.3t.3.7t-.3.7L11.45 19.55q-.7.7-1.6 1.075T7.95 21m1.25-6.2q-.3-.3-.3-.712t.3-.713L13.375 9.2q.3-.3.713-.3t.712.3t.3.713t-.3.712L10.625 14.8q-.3.3-.712.3t-.713-.3m6.3-.725q-.3-.3-.3-.7t.3-.7l2.65-2.625q.425-.425.625-.95t.2-1.1q0-1.25-.85-2.125T16.025 5q-.575 0-1.112.213t-.963.637L11.325 8.5q-.3.3-.7.3t-.7-.3t-.3-.712t.3-.713L12.55 4.45q.7-.7 1.6-1.075T16.05 3q2.05 0 3.488 1.45t1.437 3.525q0 .975-.363 1.875t-1.062 1.6l-2.625 2.625q-.3.3-.712.3t-.713-.3"/></svg>'

	return pandoc.Div({
			pandoc.RawBlock('html',
				'<details>'
					.. '<summary>'
					.. '<span id="' .. id .. '-caption" class="random-table-caption">' .. caption .. '</span>'
					.. '<span class="random-table-result" role="status" aria-live="polite" aria-atomic="true">Show all rows</span>'
					.. '</summary>'
			),

			table,

			pandoc.RawBlock('html',
				'</details>'
					.. '<div class="random-table-actions">'
					.. '<a class="random-table-link" href="#' .. id .. '">' .. link_svg .. '</a>'
					.. '<button type="button" class="random-table-roll" hidden aria-describedby="' .. id .. '-caption">Roll</button>'
					.. '</div>'
			)
		},
		pandoc.Attr(id, { 'random-table' })
	)
end
