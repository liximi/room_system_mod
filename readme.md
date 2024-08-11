# 房间 Room

本mod为原本游戏添加了房间系统。

在由墙体构成的特定尺寸范围内的封闭区域中，通过放置所需的物品、建筑等来形成特定的房间。不同的房间可以产生不同的效果。


## 关于技术 About Technology

房间系统的技术底层基于一个**区域系统**，该系统的实现思路来自**《环世界》(*RimWorld*)**的作者发布的视频。

* [Bibibili链接](https://www.bilibili.com/video/BV1gN4y1j7Kn "https://www.bilibili.com/video/BV1gN4y1j7Kn")
* [YouTube链接](https://www.youtube.com/watch?v=RMBQn_sg7DA&t=798s "https://www.youtube.com/watch?v=RMBQn_sg7DA&amp;t=798s")


## 给Modder们 For Modders

通过依赖本Mod，你可以在你自己的Mod中使用房间系统，添加新的房间类型。


### 如何依赖？ How to depend?

在 `modinfo.lua`中使用官方的依赖配置格式：

```lua
mod_dependencies = {
    {
        [chinese and "房间" or "Rooms"] = true,
    },
}
```


### 如何添加新的房间类型？ How to add a new room type?

依赖后，你可以调用本Mod提供的全局函数

```lua
function AddM23MRoom(room_data)
    --添加成功将会返回true，否则返回nil
end
--[[
room_data: 房间配置数据

]]
```
