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
	local described_by = id and ' aria-describedby="' .. id .. '-caption"' or ''
	local link = id and '<a class="random-table-link" href="#' .. id .. '">Link to table</a>' or ''

	local controls = {
		pandoc.RawInline('html', '<button type="button" class="random-table-roll" hidden' .. described_by .. '>Roll</button> ' .. link)
	}

	if caption then
		controls[#controls + 1] = pandoc.Space()
		controls[#controls + 1] = pandoc.Span(
			{ pandoc.Str(caption) },
			pandoc.Attr(id .. '-caption', { 'random-table-caption' })
		)
	end

	return pandoc.Div({
			pandoc.Div({
					pandoc.Plain(controls),
					pandoc.Div({},
						pandoc.Attr('', { 'random-table-result' }, {
							role = 'status',
							['aria-live'] = 'polite',
							['aria-atomic'] = 'true'
						})
					)
				},
				pandoc.Attr('', { 'random-table-controls' })
			),

			pandoc.RawBlock('html', '<details><summary' .. described_by .. '>Show full table</summary>'),
			table,
			pandoc.RawBlock('html', '</details>')
		},
		pandoc.Attr(id, { 'random-table' })
	)
end
