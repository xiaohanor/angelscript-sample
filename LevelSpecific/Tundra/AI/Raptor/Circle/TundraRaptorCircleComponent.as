class UTundraRaptorCircleComponent : UActorComponent
{
	AHazeActor HazeOwner;
	TArray<FVector> CircleLocations;
	FVector CurrentCircleLocation;
	bool bStrafeLeft;
	bool bCircling;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.BlockCapabilities(TundraRaptorTags::TundraRaptorCircle, this);
		
		UHazeTeam Team = HazeTeam::GetTeam(TundraRaptorTags::TundraRaptorPointTeam);
		if(Team == nullptr)
			return;

		for(AHazeActor Member: Team.GetMembers())
		{
			if (Member == nullptr)
				continue;
			CircleLocations.Add(Member.ActorLocation);
		}
	}

	UFUNCTION()
	void StartCircling(AHazePlayerCharacter Player)
	{
		if(bCircling)
			return;
		bCircling = true;
		bStrafeLeft = Math::RandBool();
		HazeOwner.UnblockCapabilities(TundraRaptorTags::TundraRaptorCircle, this);

		float ClosestPointDistance = BIG_NUMBER;
		for(FVector Location: CircleLocations)
		{
			float Distance = Location.Distance(Player.ActorLocation);
			if(Distance < ClosestPointDistance)
			{
				ClosestPointDistance = Distance;
				CurrentCircleLocation = Location;
			}
		}
	}
	
	UFUNCTION()
	void StopCircling()
	{
		if(!bCircling)
			return;
		bCircling = false;
		HazeOwner.BlockCapabilities(TundraRaptorTags::TundraRaptorCircle, this);
	}
}