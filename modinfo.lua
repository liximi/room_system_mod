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
        name = "Language",
        label = "Language",
        hover = "Set Language/设置语言",
        options =
        {
            {description = "English", data = "ENGLISH"},
            {description = "中文", data = "CHINESE"},
            {description = "Auto/自动", data = "AUTO"}
        },
        default = "AUTO",
    },
}