class ACoastWaterskiBlockRespawnZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool IsPointWithinZone(FVector Point)
	{
		return TriggerComp.Shape.IsPointInside(TriggerComp.WorldTransform, Point);
	}
}