class UGravityBikeSplineExplodeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Death);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AGravityBikeSpline GravityBike;
	AHazePlayerCharacter Driver;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		Driver = GravityBike.GetDriver();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Driver.IsPlayerDead() && !Driver.IsPlayerRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Driver.IsPlayerDead() && !Driver.IsPlayerRespawning())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnExplode(GravityBike);
		GravityBike.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.RemoveActorDisable(this);
	}
};