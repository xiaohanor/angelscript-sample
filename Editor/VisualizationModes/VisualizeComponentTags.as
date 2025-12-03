const FLinearColor VisualizeWithTagColor(1.f, 0.f, 1.f, 1.f);
const FLinearColor VisualizeNotTagColor(1.f, 0.f, 0.f, 1.f);

class UVisualizeComponentTags
{
    UFUNCTION()
    bool VisualizeWalkable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"Walkable");
    }

    UFUNCTION()
    bool VisualizeNotWalkable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeNotTag(Object, OutColor, n"Walkable");
    }

    UFUNCTION()
    bool VisualizeAlwaysBlockCamera(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"AlwaysBlockCamera");
    }

    UFUNCTION()
    bool VisualizeHideOnCameraOverlap(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"HideOnCameraOverlap");
    }

    UFUNCTION()
    bool VisualizeWallRunnable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"WallRunnable");
    }

    UFUNCTION()
    bool VisualizeWallScrambleable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"WallScrambleable");
    }

    UFUNCTION()
    bool VisualizeDarkPortalPlaceable(UObject Object, FLinearColor& OutColor) const
    {
        return VisualizeTag(Object, OutColor, n"DarkPortalPlaceable");
    }

    bool VisualizeTagOrNot(UObject Object, FLinearColor& OutColor, FName Tag) const
    {
        UPrimitiveComponent Component = Cast<UPrimitiveComponent>(Object);
        if (Component == nullptr)
            return false;
		auto Material = Component.GetMaterial(0);
		if (Material == nullptr)
			return false;
		if (Material.BlendMode == EBlendMode::BLEND_Translucent)
			return false;
		if (Material.BlendMode == EBlendMode::BLEND_Additive)
			return false;

        if (Component.HasTag(Tag))
		{
			OutColor = FLinearColor::Green;
			return true;
		}
		else
		{
			OutColor = FLinearColor::Red;
			return true;
		}
    }

    bool VisualizeTag(UObject Object, FLinearColor& OutColor, FName Tag) const
    {
        UPrimitiveComponent Component = Cast<UPrimitiveComponent>(Object);
        if (Component == nullptr)
            return false;
		auto Material = Component.GetMaterial(0);
		if (Material == nullptr)
			return false;
		if (Material.BlendMode == EBlendMode::BLEND_Translucent)
			return false;
		if (Material.BlendMode == EBlendMode::BLEND_Additive)
			return false;

        if (!Component.HasTag(Tag))
            return false;

        OutColor = VisualizeWithTagColor;
        return true;
    }

    bool VisualizeNotTag(UObject Object, FLinearColor& OutColor, FName Tag) const
    {
        UPrimitiveComponent Component = Cast<UPrimitiveComponent>(Object);
        if (Component == nullptr)
            return false;
		auto Material = Component.GetMaterial(0);
		if (Material == nullptr)
			return false;
		if (Material.BlendMode == EBlendMode::BLEND_Translucent)
			return false;
		if (Material.BlendMode == EBlendMode::BLEND_Additive)
			return false;

        if (Component.HasTag(Tag))
            return false;

        OutColor = VisualizeNotTagColor;
        return true;
    }
};