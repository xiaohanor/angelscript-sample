class USolarFlareSplineRespawnCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	USolarFlareSplineRespawnComponent SplineRespawnComp;
	UPlayerHealthComponent PlayerHealthComp;

	const float TraceHeight = 2000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineRespawnComp = USolarFlareSplineRespawnComponent::Get(Player);
		PlayerHealthComp = UPlayerHealthComponent::Get(Player);
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
		Player.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"OnRespawned"), EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearRespawnPointOverride(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private bool OnRespawned(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation)
	{
		auto RespawnTrigger = SplineRespawnComp.RespawnTrigger;
		
		auto OtherPlayer = Player.OtherPlayer;
		FVector DirToRight;
		if(RespawnTrigger.RespawnSpline == nullptr)
		{
			DirToRight = RespawnTrigger.ActorRightVector;
		}
		else
		{
			auto SplineComp = RespawnTrigger.RespawnSpline.Spline;
			auto ClosestSplinePosToOtherPlayer = SplineComp.GetClosestSplinePositionToWorldLocation(OtherPlayer.ActorLocation);
			DirToRight = ClosestSplinePosToOtherPlayer.WorldRightVector;
		}

		FQuat RespawnRotation = FQuat::MakeFromYZ(DirToRight, FVector::UpVector);
		OutLocation.RespawnTransform.SetRotation(RespawnRotation);

		FVector SideOffset;
		if(RespawnTrigger.bPreferRightSideRespawn)
			SideOffset = DirToRight * RespawnTrigger.RespawnDistanceToSide;
		else
			SideOffset = -DirToRight * RespawnTrigger.RespawnDistanceToSide;

		FVector Start = OtherPlayer.ActorLocation + SideOffset 
			+ FVector::UpVector * TraceHeight * 0.5;

		FVector End = Start 
			+ FVector::DownVector * TraceHeight;

		FHazeTraceSettings PreferredSideTrace;
		PreferredSideTrace.TraceWithPlayer(Player);
		auto PreferredHit = PreferredSideTrace.QueryTraceSingle(Start, End);
		// Hit on preferred side
		if(PreferredHit.bBlockingHit)
		{
			OutLocation.RespawnTransform.SetLocation(PreferredHit.ImpactPoint);
			return true;
		}
		else
		{
			FHazeTraceSettings OtherSideTrace;
			OtherSideTrace.TraceWithPlayer(Player);
			Start = OtherPlayer.ActorLocation - SideOffset
				+ FVector::UpVector * TraceHeight * 0.5;
			
			End = Start
				+ FVector::DownVector * TraceHeight;
			auto OtherSideHit = OtherSideTrace.QueryTraceSingle(Start, End);
			// Hit on other side
			if(OtherSideHit.bBlockingHit)
			{
				OutLocation.RespawnTransform.SetLocation(OtherSideHit.ImpactPoint);
				return true;
			}
			// Neither side hit, don't know what to do :)
			else
			{
				return false;
			}
		}
	}
};