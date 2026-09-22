--[[
	Colours and fonts for every screen.
]]

return {
	Colors = {
		Backdrop = Color3.fromRGB(6, 7, 11),
		Panel = Color3.fromRGB(19, 21, 30),
		PanelLight = Color3.fromRGB(28, 31, 44),
		PanelLighter = Color3.fromRGB(38, 42, 58),
		Stroke = Color3.fromRGB(50, 55, 78),
		Text = Color3.fromRGB(236, 238, 246),
		SubText = Color3.fromRGB(146, 152, 176),
		Gold = Color3.fromRGB(255, 196, 46),
		GoldDeep = Color3.fromRGB(214, 140, 20),
		Accent = Color3.fromRGB(124, 92, 255),
		Good = Color3.fromRGB(55, 214, 122),
		Bad = Color3.fromRGB(255, 90, 90),
	},
	Fonts = {
		Regular = Font.fromEnum(Enum.Font.BuilderSans),
		Medium = Font.fromEnum(Enum.Font.BuilderSansMedium),
		Bold = Font.fromEnum(Enum.Font.BuilderSansBold),
		Heavy = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
	},
}
