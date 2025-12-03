class UStormDragonFollowSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonFollowSplineCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	
	AStormDragonChase StormDragon;
	UHazeSplineComponent SplineComp;
	FSplinePosition SplineData;

	float MinDist = 15000.0;
	float MaxDist = 21000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonChase>(Owner);
		SplineComp = UHazeSplineComponent::Get(StormDragon.Spline);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineData = SplineComp.GetClosestSplinePositionToWorldLocation(StormDragon.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineData.Move(StormDragon.MoveSpeed * GetScalar() * DeltaTime);
		StormDragon.ActorLocation = SplineData.WorldLocation;
		StormDragon.ActorRotation = SplineData.WorldRotation.Rotator();
	}

	float GetScalar()
	{
		float Multiplier = 1.0;
		float Dist = (GetClosestPlayer().ActorLocation - StormDragon.ActorLocation).Size();

		if (Dist < MinDist)
		{
			float ToAdd = 1.0 - Dist / MinDist;
			Multiplier += ToAdd + 0.2;
		}

		if (Dist > MaxDist)
		{
			Multiplier = MaxDist / Dist;
		}

		return Multiplier;
	}

	AHazePlayerCharacter GetClosestPlayer()
	{
		return Game::Mio.GetDistanceTo(StormDragon) < Game::Zoe.GetDistanceTo(StormDragon) ? Game::Mio : Game::Zoe; 
	}
} 