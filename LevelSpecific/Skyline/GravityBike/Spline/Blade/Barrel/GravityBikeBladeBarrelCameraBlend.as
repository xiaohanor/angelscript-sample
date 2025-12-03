asset GravityBikeBladeBarrelCameraBlend of UGravityBikeBladeBarrelCameraBlend
{
}

/**
 * Cursed custom blend to face the camera towards a specific world direction (don't judge me)
 */
class UGravityBikeBladeBarrelCameraBlend : UCameraDefaultBlend
{
	UFUNCTION(BlueprintOverride)
	bool BlendView(FHazeViewBlendInfo& SourceView, FHazeViewBlendInfo TargetView,
	               FHazeViewBlendInfo& OutCurrentView, FHazeCameraViewPointBlendInfo BlendInfo,
	               FHazeCameraViewPointBlendAdvanced AdvancedInfo) const
	{
		FHazeViewBlendInfo NewTargetView = TargetView;
		// Hard copied from the target rotation in the level lol
		NewTargetView.Rotation = FRotator(0, -45, 0);
		return Super::BlendView(SourceView, NewTargetView, OutCurrentView, BlendInfo, AdvancedInfo);
	}
}