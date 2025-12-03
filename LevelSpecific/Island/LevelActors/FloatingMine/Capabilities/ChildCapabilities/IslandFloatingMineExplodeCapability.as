class UIslandFloatingMineExplodeCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AIslandFloatingMine Mine;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandFloatingMine>(Owner);
		MoveComp = UHazeMovementComponent::Get(Mine);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		for(auto Player : Game::Players)
		{
			float DistSqrd = Player.ActorCenterLocation.DistSquared(Mine.BobRoot.WorldLocation);
			if(DistSqrd <= Math::Square(Mine.ExplosionTriggerRadius))
				return true;
		}

		if(MoveComp.HasWallContact())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(MoveComp.HasCeilingContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Mine.Explode();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}
}