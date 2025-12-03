UCLASS(NotBlueprintable)
class APinballTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UPinballTriggerComponent TriggerComp;
};