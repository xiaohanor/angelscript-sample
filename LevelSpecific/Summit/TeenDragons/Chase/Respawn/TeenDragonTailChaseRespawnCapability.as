class UTeenDragonTailChaseRespawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default TickGroup = EHazeTickGroup::Gameplay;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonChaseComponent ChaseComp;
	UPlayerMovementComponent MoveComp;

	const float RespawnDownTraceDistance = 10000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		ChaseComp = UTeenDragonChaseComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ChaseComp.bIsInChase)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ChaseComp.bIsInChase)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyRespawnPointOverrideDelegate(this, 
			FOnRespawnOverride(this, n"OnRespawnOverride"), EInstigatePriority::High);
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearRespawnPointOverride(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private bool OnRespawnOverride(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation)
	{
		if(ChaseComp.ChaseSpline == nullptr)
		{
			PrintError("TeenDragonTailChaseRespawnCapability is trying to respawn, but the chase spline is nullptr");
			return false;
		}

		auto SplineComp = ChaseComp.ChaseSpline.Spline;

		auto OtherPlayerClosestSplinePos = 
			SplineComp.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);

		float SplinePosDistance = OtherPlayerClosestSplinePos.CurrentSplineDistance - TeenDragonChaseRollingSettings::RespawnBehindDistance;
		auto RespawnSplinePos = SplineComp.GetSplinePositionAtSplineDistance(SplinePosDistance);

		FHazeTraceSettings RespawnTrace;
		RespawnTrace.UseCapsuleShape(Player.CapsuleComponent.CapsuleRadius, Player.ScaledCapsuleHalfHeight);
		RespawnTrace.TraceWithPlayer(Player);
		auto Hit = RespawnTrace.QueryTraceSingle(RespawnSplinePos.WorldLocation, RespawnSplinePos.WorldLocation + FVector::DownVector * RespawnDownTraceDistance);
		
		TEMPORAL_LOG(ChaseComp)
			.HitResults("Respawn Trace", Hit, RespawnTrace.Shape)
		;

		if(Hit.bBlockingHit)
		{
			OutLocation.RespawnTransform.SetLocation(Hit.ImpactPoint);
			OutLocation.RespawnTransform.SetRotation(RespawnSplinePos.WorldRotation);
			return true;
		}
		PrintError("TeenDragonTailChaseRespawnCapability did not find the ground from the spline, respawning at last respawn point");
		return false;
	}
	
};