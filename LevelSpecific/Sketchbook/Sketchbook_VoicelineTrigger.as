UCLASS(Abstract)
class ASketchbook_VoicelineTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapComp;
};
