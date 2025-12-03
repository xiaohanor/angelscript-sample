UCLASS(NotBlueprintable)
class AStoneBeastHeadFocusTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};