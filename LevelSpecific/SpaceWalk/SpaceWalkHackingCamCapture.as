UCLASS(Abstract)
class ASpaceWalkHackingCamCapture : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCapture;
};
