class USkylineTorTargetingComponent : UActorComponent
{
	private ASkylineTorCenterPoint CenterPoint;
	float OwnerRadius;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CenterPoint = TListedActors<ASkylineTorCenterPoint>().Single;
		OwnerRadius = Cast<AHazeCharacter>(Owner).CapsuleComponent.CapsuleRadius;
	}

	FVector GetZoeLocation() property
	{
		return GetPlayerLocation(Game::Zoe);
	}

	FVector GetMioLocation() property
	{
		return GetPlayerLocation(Game::Mio);
	}

	FVector GetPlayerLocation(AHazePlayerCharacter Player)
	{
		FVector Location = Player.ActorLocation;
		float Radius = CenterPoint.ArenaRadius - OwnerRadius * 1.5;
		if(CenterPoint.ActorLocation.Dist2D(Player.ActorLocation) > Radius)
		{
			FVector Dir = (Player.ActorLocation - CenterPoint.ActorLocation).GetSafeNormal2D();
			Location = CenterPoint.ActorLocation + Dir * Radius;
		}

		FVector NavMeshLocation;
		if(Pathfinding::FindNavmeshLocation(Location, 100, 500, NavMeshLocation))
			return NavMeshLocation;
		return Location;
	}
}