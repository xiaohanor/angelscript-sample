class UTeenDragonAcidChaseRespawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default TickGroup = EHazeTickGroup::Gameplay;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonChaseComponent ChaseComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
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
			PrintError("TeenDragonAcidChaseRespawnCapability is trying to respawn, but the chase spline is nullptr");
			return false;
		}

		auto SplineComp = ChaseComp.ChaseSpline.Spline;

		auto OtherPlayerClosestSplinePos = 
			SplineComp.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);

		float SplinePosDistance = OtherPlayerClosestSplinePos.CurrentSplineDistance - TeenDragonAutoGlideStrafeSettings::RespawnBehindDistance;
		auto RespawnSplinePos = SplineComp.GetSplinePositionAtSplineDistance(SplinePosDistance);

		OutLocation.RespawnTransform.SetLocation(RespawnSplinePos.WorldLocation);
		OutLocation.RespawnTransform.SetRotation(RespawnSplinePos.WorldRotation);

		return true;
	}
	
};