class UGravityBikeFreeDriverInputMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);

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
		GravityBike.BlockCapabilities(CapabilityTags::Input, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		GravityBike.UnblockCapabilities(CapabilityTags::Input, this);
	}
};