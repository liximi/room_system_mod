# 房间

本mod为原本游戏添加了房间系统，就像在《缺氧》中的那样。

在由墙体构成的特定尺寸范围内的封闭区域中，通过放置所需的物品、建筑等来形成特定的房间。不同的房间可以产生不同的效果。

## 特别注意

**开启本Mod将会大幅增加内存占用，同时也会大幅增加游戏载入时间。对比数据如下。**

不开启洞穴：

|             | 主机端 | 连入的客户端 |
| ----------- | ------ | ------------ |
| 不开任何Mod | 2.9G   | 2.6G         |
| 开启本Mod   | 4.2G   | 3.5G         |

开启洞穴：

|               | 地上服务端 | 洞穴服务端 | 地上，连入的客户端 | 洞穴，连入的客户端 |
| ------------- | ---------- | ---------- | ------------------ | ------------------ |
| 不开启任何Mod | 0.97G      | 0.84G      | 2.5G(主机2.1G)     | 2.4G(主机2G)       |
| 开启本Mod     | 2.4G       | 1.7G       | 3.2G(主机3.8G)     | 2.8G(主机4.2G)     |

**另外，当其他玩家连入游戏时，会存在几秒到十几秒的卡顿，这是在从主机或者服务器上接收数据。**

## 关于技术

房间系统的技术底层基于一个**区域系统**，该系统的实现思路来自《环世界》(*RimWorld*) 的作者发布的视频。

* [Bilibili链接](https://www.bilibili.com/video/BV1gN4y1j7Kn "https://www.bilibili.com/video/BV1gN4y1j7Kn")
* [YouTube链接](https://www.youtube.com/watch?v=RMBQn_sg7DA&t=798s "https://www.youtube.com/watch?v=RMBQn_sg7DA&amp;t=798s")

## 给Modder们

通过依赖本Mod，你可以在你自己的Mod中使用房间系统，添加新的房间类型。

**你不应该在复制本Mod的代码后直接使用或修改后将其用于其他Mod中。**

### 如何依赖？

在 `modinfo.lua`中配置加载优先级为**负数。**（本mod的优先级为0，因此负数优先级可以使你的mod在本mod加载完之后才加载）

```lua
priority = 负数
```

在 `modinfo.lua`中使用官方的依赖配置格式：

```lua
local chinese = locale == "zh" or locale  == "zhr"
mod_dependencies = {
    {
        [chinese and "房间" or "Rooms"] = true,
    },
}
```

### 如何添加新的房间类型？

依赖后，你可以在modmain中调用（需要在主机和客机都调用）本Mod提供的全局函数。

```lua
--src: m23m_main_scripts\modified_mechanics\mod_room_key_items.lua
--添加成功将会返回true，否则返回nil
function AddM23MRoom(room_data) end
```

`room_data`是房间配置数据，`table`类型，支持的配置字段如下:

| key             | data type       | note                                                                                                                                                                                                                 |
| --------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| type            | string          | 房间类型，要确保该类型是唯一的，不能与其他房间类型重复。必须配置。                                                                                                                                                   |
| name            | string          | 房间名称。可以不指定(不推荐)，默认值为 `STRINGS.M23M_ROOMS.NO_NAME.NAME`。                                                                                                                                         |
| desc            | string/function | 房间描述，用来描述房间的效果。可以是一个函数，但必须返回一个 `string`。<br />可以不指定(不推荐)，默认值为 `STRINGS.M23M_ROOMS.NO_NAME.DESC`。                                                                    |
| priority        | integer         | 判断房间是否形成的优先级，必须为正数，数字越大越优先被判断。<br />可以不指定，默认值为当前所有房间类型中的最大优先级+1。                                                                                             |
| min_size        | integer         | 形成该房间所需的最小面积。可以不指定，默认值为 `16`（1个地皮的面积）。                                                                                                                                             |
| max_size        | integer         | 形成该房间所需的最大面积，**不建议过大，可能导致性能问题**。<br />可以不指定，默认值为 `128`（8个地皮的面积）。                                                                                              |
| must_items      | table           | 形成该房间所需的物品。必须配置。配置格式在后文详述。                                                                                                                                                                 |
| available_tiles | table           | 形成该房间所需的地皮。若无需求，可以不配置。配置格式在后文详述。                                                                                                                                                     |
| color           | table           | 该房间在地图上显示的颜色。<br />格式示例：`{0.55, 0.23, 0.77, 1}`，建议直接使用官方提供的颜色构造函数：`RGB(r, g, b)`。<br />可以不指定(不推荐)，默认值为随机生成的颜色，且在每个客户端上每次开启游戏都不相同。 |
| icon_atlas      | string          | 该房间的图标对应的 `xml`文件路径。可以不指定，默认值为通用房间图标。<br />必须和icon_image同时存在。                                                                                                               |
| icon_image      | string          | 该房间的图标对应的 `tex`文件路径。可以不指定，默认值为通用房间图标。<br />必须和icon_atlas同时存在                                                                                                                 |

#### must_items 配置格式

`must_items`是一个数组，依次放入 `prefab`或 `prefab组`，**不要指定key**

1. prefab字符串：表示房间中必须存在该物品。
2. prefab字符串数组：表示房间中存在该数组中的任意一种物品即可。

```lua
--示例1：
must_items = {
    "researchlab2", --炼金引擎
    "researchlab3", --暗影操控器
    "cartographydesk", --制图桌
}
--示例2：
must_items = {
    {"tent", "portabletent"}, --帐篷/宿营帐篷
}
--示例3：
must_items = {
    {"cookpot", "portablecookpot"}, --普通锅或便携锅
    "icebox", --冰箱
}
```

#### available_tiles 配置格式

`available_tiles`由 `地皮ID`作为key，由 `true`作为value。

你可以在官方文件 `scripts/tiledefs.lua` 中找到这些 `ID`。

```lua
--示例：
local INDOOR_TILES = {
    SHELLBEACH = true,	--贝壳海滩地皮
    MONKEY_GROUND = true,	--月亮码头海滩地皮
    BEARD_RUG = true,		--胡须地毯
    WOODFLOOR = true,	--木地板
    COTL_GOLD = true,	--黄金地板
    COTL_BRICK = true,	--砖地板
    CHECKER = true,	--棋盘地板
    CARPET = true,	--地毯地板
    CARPET2 = true,	--茂盛地毯
    MOSAIC_GREY = true,	--灰色马赛克地板
    MOSAIC_RED = true,	--红色马赛克地板
    MOSAIC_BLUE = true,	--蓝色马赛克地板
}
```

#### 示例数据

你可以在另一个Mod："房间基础内容包(Base Rooms Package)"的 `scripts/rbc_room_def.lua`文件中找到房间的配置数据。
