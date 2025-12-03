class UTundraRiverBoulderPlayerRespawningCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ATundraRiverBoulder Boulder;
	UPlayerRespawnComponent MioRespawnComp;
	UPlayerRespawnComponent ZoeRespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boulder = Cast<ATundraRiverBoulder>(Owner);

		MioRespawnComp = UPlayerRespawnComponent::Get(Game::Mio);
		ZoeRespawnComp = UPlayerRespawnComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boulder.bIsActive)
			return false;

		if(Boulder.RespawnSplines.Num() == 0)
			return false;

		if(Boulder.IsPlayerRespawningBlocked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boulder.bIsActive)
			return true;

		if(Boulder.RespawnSplines.Num() == 0)
			return true;

		if(Boulder.IsPlayerRespawningBlocked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MioRespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"GetPlayerRespawnLocation"), EInstigatePriority::High);
		ZoeRespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"GetPlayerRespawnLocation"), EInstigatePriority::High);
		MioRespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
		ZoeRespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MioRespawnComp.ClearRespawnOverride(this);
		ZoeRespawnComp.ClearRespawnOverride(this);
		MioRespawnComp.OnPlayerRespawned.Unbind(this, n"OnPlayerRespawn");
		ZoeRespawnComp.OnPlayerRespawned.Unbind(this, n"OnPlayerRespawn");
	}

	UFUNCTION()
	private void OnPlayerRespawn(AHazePlayerCharacter Player)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, false);
		FPlayerAutoRunSettings AutoRunSettings;
		AutoRunSettings.bCancelOnPlayerInput = true;
		AutoRunSettings.bSprint = true;
		AutoRunSettings.CancelAfterDuration = 200;
		Player.ApplyAutoRunAlongSpline(this, Boulder.FollowSpline.Get().Spline, AutoRunSettings);
	}

	UFUNCTION()
	private bool GetPlayerRespawnLocation(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		FVector CheckLocation = Player.GetOtherPlayer().GetActorLocation();

		//If "OtherPlayer" is behind the boulder or very close to it, get a location further ahead of the boulder instead.
		if(CheckLocation.Distance(Boulder.ActorLocation) < Boulder.DistanceAheadOfBoulderToRespawn
		|| Boulder.ActorForwardVector.DotProduct(CheckLocation - Boulder.ActorLocation) < 0)	
		{
			 CheckLocation = Boulder.ActorLocation + Boulder.ActorForwardVector * Boulder.DistanceAheadOfBoulderToRespawn;
		}

		FVector ClosestLocation;
		float ClosestSqrDistance = MAX_flt;
		for(auto RespawnSpline : Boulder.RespawnSplines)
		{
			FVector SplineLocation = RespawnSpline.Get().Spline.GetClosestSplineWorldLocationToWorldLocation(CheckLocation);
			float SqrDistance = SplineLocation.DistSquared(CheckLocation);

			if(SqrDistance < ClosestSqrDistance
			&& Boulder.ActorForwardVector.DotProduct(SplineLocation - Boulder.ActorLocation) > 0)
			{
				ClosestLocation = SplineLocation;
				ClosestSqrDistance = SqrDistance;
			}
		}

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		FHitResult Hit = Trace.QueryTraceSingle(ClosestLocation, ClosestLocation + FVector::DownVector * 5000.0);
		if(Hit.bBlockingHit)
			ClosestLocation = Hit.Location;

		OutLocation.RespawnTransform = FTransform(Boulder.ActorRotation, ClosestLocation);
		return true;
	}
}