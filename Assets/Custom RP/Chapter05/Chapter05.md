# 烘焙光

## 1 烘焙静态光

+ 到目前为止，我们已经在渲染时计算了所有照明，但这不是唯一的选项。照明也可以提前计算并存储在光照图和探测器中。这样做的主要原因有两个：减少实时计算量和添加运行时无法计算的间接照明。后者是统称为全局照明的一部分：光不是直接来自光源，而是通过反射、环境或发射表面间接产生的。

+ 烘焙照明的缺点是它是静态的，因此在运行时无法更改。它还需要存储，这增加了构建大小和内存使用率。

> 1.1 场景照明设置

+ 全局照明是通过 `Lighting` 窗口的 `Scene` 选项卡按场景配置的。烘焙照明是通过 `Mixed Lighting` 下的 `Baked Global Illumination` 切换启用的。还有一个 `Lighting Mode` 选项，我们将设置 `Baked Indirect` ，这意味着我们烘焙所有静态间接照明。

+ 下面是 `Lightmapping Settings` 部分，可用于控制由 `Unity` 编辑器完成的光照贴图过程。我将使用默认设置，除了 `LightMap Resolution` 降低到20、 `Compress Lightmaps` 禁用以及 `Directional Mode` 设置为 `Non-Directional` 。我也使用渐进式CPU光映射器。

> 1.2 静态对象

+ 为了演示烘焙照明，我创建了一个场景，以绿色平面为地面，几个长方体和球体，中心的结构只有一个开放的侧面，因此其内部被完全遮蔽。

+ 场景中有一个 `Mode` 设置为 `Mixed` 的单向灯光。这告诉 `Unity` 应该为该灯光烘焙间接照明。此外，该灯光仍然像常规实时灯光一样工作。
  
+ 我还包括平面和所有立方体，包括那些在烘培过程中形成结构的立方体。它们将是光纤反射的对象，从而变得间接。这是通过启用其 `MeshRenderer` 组件的 `Contribute Global Illumination` 切换来实现的。启用此选项还会自动将其 `Receive Global Illumination` 模式切换为 `Lightmaps` ，这意味着到达其曲面的间接光将烘焙到光照贴图中。您也可以通过从对象的 `Static` 下拉列表中启用 `Contribute GI` 或使其完全静态来启用此模式。

+ 启用后，场景的照明将再次烘焙，假设在 `Lighting` 窗口中启用了 `Auto Generate` ，否则必须按下 `Generate Lighting` 按钮。光照贴图设置也显示在 `MeshRenderer ` 组件中，包括包含对象的光照贴图的视图。

+ 球体不会显示在灯光贴图中，因为它们对全局照明没有贡献，因此被视为动态的。他们将不得不依赖光探测器，我们稍后将对此进行介绍。静态对象也可以通过将其 `Receive Global Illumination ` 模式切换回 `Light Probes` 而从贴图中排除。它们仍然会影响烘焙结果，但不会占用灯光贴图中的空间。

> 1.3 完全烘焙的灯光

+ 烘焙的照明大多是蓝色的，因为它由 `skybox` 框主导，该框表示来自环境天空的间接照明。中心建筑周围较亮的区域是由光源从地面和墙壁反射的间接照明引起的。

+ 我们还可以将所有照明烘焙到地图中，包括直接照明和间接照明。这是通过将灯光的 `Mode` 设置为 `Baked` 来完成的。然后它不再提供实时照明。

+ 实际上，烘焙光的直接光也被视为间接光，因此最终会出现在贴图中，使其更加明亮。

## 2 烘焙灯光采样

+ 由于没有实时灯光，而且我们的着色器还不知道全局照明，因此当前所有内容都渲染为纯黑色。我们必须对光照图进行采样才能使其工作。
  
> 2.1 全局照明

+ 创建一个新的 `ShaderLibrary/GI.hlsl` 文件，以包含与全局照明相关的所有代码。在其中，定义一个 `GI` 结构和一个 `GetGI` 函数来检索它，给定一些灯光贴图 `UV` 坐标。间接光来自所有方向，因此只能用于漫反射照明，而不能用于镜面反射。因此，给 `GI` 结构一个漫反射颜色场。最初使用灯光贴图UV填充它，用于调试目的。

+ 在累积实时照明之前，将 `GI` 参数添加到 `GetLighting` 并使用它初始化颜色值。在这一点上，我们不会将其与曲面的漫反射相乘，这样我们就可以看到未修改的接收光。

+ 在 `LitPass` 中 `Lighting ` 之前 `include GI` 。

+ 在 `LitPassFragment` 中获取全局照明数据，最初使用零 `UV` 坐标，然后将其传递给 `GetLighting` 。
  
> 2.2 灯光贴图坐标