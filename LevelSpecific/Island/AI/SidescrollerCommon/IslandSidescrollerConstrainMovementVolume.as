class AIslandSidescrollerConstrainMovementVolume : AVolume
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	float GetMinLocationX()
	{
		float MinLocationX = ActorLocation.X - Bounds.BoxExtent.X;
		return MinLocationX;
	}

	float GetMaxLocationX()
	{
		float MaxLocationX = ActorLocation.X + Bounds.BoxExtent.X;
		return MaxLocationX;
	}
}