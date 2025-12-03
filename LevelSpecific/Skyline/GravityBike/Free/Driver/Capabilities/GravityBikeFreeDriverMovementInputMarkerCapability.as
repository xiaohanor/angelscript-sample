class UGravityBikeFreeDriverMovementInputMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	AHazePlayerCharacter Player;
	AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GravityBike = GravityBikeFree::GetGravityBike(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		GravityBike.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		if(GravityBike == nullptr)
			return;

		GravityBike.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
};