class UMoveRatioAnimationsContentBrowserFilter : UHazeScriptContentBrowserFilter
{
	default Color = FLinearColor::Yellow;
	default FilterName = "Anims using Move Ratio";
	default Tooltip = "Shows all animation assets that have Movement Ratio enabled.";
	default Category = "Animation";

	UFUNCTION(BlueprintOverride)
	bool IsAllowedByFilter(FString ObjectPath, FString AssetClass, FName AssetName, FName PackageName, FName PackagePath) const
	{
		if (AssetClass != "/Script/Engine.AnimSequence")
			return false;
		UAnimSequence Anim = Cast<UAnimSequence>(Editor::LoadAsset(FName(ObjectPath)));
		if (Anim == nullptr)
			return false;
		if (!Anim.IsMoveRatioEnabled())
		 	return false;
		return true;
	}
}
