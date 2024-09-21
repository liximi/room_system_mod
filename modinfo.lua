local chinese = locale == "zh" or locale  == "zhr"

name = chinese and "房间" or "Rooms"
description = chinese and "本mod不包含可游玩内容！只提供对基础机制的实现！你可以订阅并开启mod：'房间基础内容包(Base Rooms Package)'来进行游玩。" or "This mod does not include playable content! Only provide implementation of basic mechanisms! You can subscribe and activate the mod: 'Base Rooms Package' to play."
author = "liximi"
version = "dev"

forumthread = ""

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = true
all_clients_require_mod=true

api_version = 10
priority = 0

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"room", "房间"}

configuration_options = {
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
}