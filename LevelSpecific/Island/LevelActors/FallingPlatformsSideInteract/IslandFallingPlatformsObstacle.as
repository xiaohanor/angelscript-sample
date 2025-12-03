UCLASS(Abstract)
class AIslandFallingPlatformsObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Board = TListedActors<AIslandFallingPlatformsBoard>().Single;

		FIslandGridPoint Point = Board.GetClosestGridPoint(ActorLocation);
		Board.AddGridPointBlocker(Point);
	}
}