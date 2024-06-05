local chinese = locale == "zh" or locale  == "zhr"

name = chinese and "房间" or "Rooms"
description = ""
author = "liximi"
version = "dev"

forumthread = ""

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = true
all_clients_require_mod=true

api_version = 10
priority = -9999

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {} --服务器标签可以不写

configuration_options =
{
    {
        name = "language",
        label = chinese and "语言" or "Language",
        hover = chinese and "设置语言" or "Set Language",
        options = {
            {description = "English", data = "ENGLISH"},
            {description = "中文", data = "CHINESE"},
            {description = "Auto/自动", data = "AUTO"}
        },
        default = "AUTO",
    },
    {
        name = "kitchen_cooktime_mult",
        label = chinese and "厨房的烹饪时间乘数" or "Cook Time Multiplier of Kitchen",
        hover = chinese and "在厨房中，烹饪时间会缩短。" or "In the kitchen, cooking time will be shortened.",
        options = {
            {description = "90%", data = -0.1},
            {description = "80%", data = -0.2},
            {description = "75%", data = -0.25},
            {description = "70%", data = -0.3},
            {description = "60%", data = -0.4},
            {description = "50%", data = -0.5},
            {description = "40%", data = -0.6},
            {description = "30%", data = -0.7},
            {description = "75%", data = -0.25},
            {description = "20%", data = -0.8},
            {description = "10%", data = -0.9},
        },
        default = -0.3,
    },
    {
        name = "ws_mult_crafting_probability",
        label = chinese and "工作间双倍产出的概率" or "Probability Double Output in Workshop",
        hover = chinese and "在工作间/化学实验室中制作物品时，双倍产出的概率。" or "The probability of double output when making items in the Workshop/Chemistry Laboratory.",
        options = {
            {description = "0%", data = 0},
            {description = "1%", data = 0.01},
            {description = "2%", data = 0.02},
            {description = "3%", data = 0.03},
            {description = "4%", data = 0.04},
            {description = "5%", data = 0.05},
            {description = "10%", data = 0.1},
            {description = "15%", data = 0.15},
            {description = "20%", data = 0.2},
            {description = "25%", data = 0.25},
            {description = "30%", data = 0.3},
        },
        default = 0.05,
    },
}