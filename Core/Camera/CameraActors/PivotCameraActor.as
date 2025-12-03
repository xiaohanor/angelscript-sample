
UCLASS(HideCategories = "InternalHiddenObjects Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects", Meta = (HighlightPlacement))
class APivotCameraActor : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	USpringArmCamera Camera;
}
