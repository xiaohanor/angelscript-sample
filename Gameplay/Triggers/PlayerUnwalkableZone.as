UCLASS(NotBlueprintable)
class APlayerUnwalkableZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPlayerUnwalkableTriggerComponent UnwalkableTriggerComp;
};