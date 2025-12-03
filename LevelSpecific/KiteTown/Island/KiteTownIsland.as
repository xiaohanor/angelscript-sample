UCLASS(Abstract)
class AKiteTownIsland : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent IslandRoot;

	UPROPERTY(DefaultComponent, Attach = IslandRoot, ShowOnActor)
	UKiteTownIslandComponent IslandComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
}