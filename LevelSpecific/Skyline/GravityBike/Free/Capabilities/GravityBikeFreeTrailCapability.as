class UGravityBikeFreeTrailCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
    default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeTrail);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;
	
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);

		Player = GravityBike.GetDriver();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.Input.Throttle < KINDA_SMALL_NUMBER)
			return false;

		if(GravityBike.IsBoosting())
			return false;

		if(!MoveComp.IsOnAnyGround())
			return false;

		if(GravityBike.IsDrifting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.Input.Throttle < KINDA_SMALL_NUMBER)
			return true;

		if(GravityBike.IsBoosting())
			return true;

		if(GravityBike.IsDrifting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeFreeEventHandler::Trigger_OnForwardStart(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeFreeEventHandler::Trigger_OnForwardEnd(GravityBike);
	}
}