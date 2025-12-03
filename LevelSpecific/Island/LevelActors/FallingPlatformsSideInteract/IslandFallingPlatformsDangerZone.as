UCLASS(Abstract)
class AIslandFallingPlatformsDangerZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDeathTriggerComponent DeathComp;
}