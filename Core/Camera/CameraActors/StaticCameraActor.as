UCLASS(hideCategories="Rendering Cooking Input Actor LOD", Meta = (HighlightPlacement))
class AStaticCameraActor : AHazeCameraActor
{   
	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UHazeCameraComponent Camera;

	// Static cameras ignores the POI settings,
	// so we don't get weird blend in, into a static
	default Camera.bCanUsePointOfInterest = false;
}
