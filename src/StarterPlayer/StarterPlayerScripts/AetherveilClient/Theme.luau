-- AETHERVEIL · Visual theme (colours and fonts used by every menu)

local Theme = {}

Theme.Colors = {
	Ink = Color3.fromRGB(7, 5, 12),
	Panel = Color3.fromRGB(17, 11, 28),
	PanelHi = Color3.fromRGB(30, 20, 48),
	Line = Color3.fromRGB(86, 66, 120),
	Text = Color3.fromRGB(238, 226, 200),
	TextDim = Color3.fromRGB(170, 158, 186),
	TextFaint = Color3.fromRGB(120, 108, 140),
	Gold = Color3.fromRGB(232, 206, 140),
	GoldLight = Color3.fromRGB(252, 242, 214),
	GoldDeep = Color3.fromRGB(140, 108, 58),
	Accent = Color3.fromRGB(194, 124, 255),
	Accent2 = Color3.fromRGB(255, 92, 224),
	Good = Color3.fromRGB(120, 230, 150),
	Bad = Color3.fromRGB(255, 100, 112),
}

local function font(enumFont, weight)
	local ok, f = pcall(Font.fromEnum, enumFont)
	if not ok then
		f = Font.fromEnum(Enum.Font.Merriweather)
	end
	return Font.new(f.Family, weight or Enum.FontWeight.Regular)
end

Theme.Fonts = {
	Display = font(Enum.Font.Bodoni, Enum.FontWeight.Bold), -- titles and menu items
	Label = font(Enum.Font.Bodoni, Enum.FontWeight.Regular), -- small caps labels
	Body = font(Enum.Font.Garamond, Enum.FontWeight.Regular), -- descriptions
	Number = font(Enum.Font.Merriweather, Enum.FontWeight.Bold), -- prices, stats
}

-- Letter-spaced uppercase text for labels ("T H E  V E I L").
function Theme.Spaced(text, gap)
	gap = gap or " "
	local chars = {}
	for _, c in utf8.codes(string.upper(text)) do
		table.insert(chars, utf8.char(c))
	end
	return table.concat(chars, gap)
end

return Theme
