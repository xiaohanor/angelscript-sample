class UGravityBikeFreeAlignWithGroundContactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeMovement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeAlignWithGroundContact);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
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
		GravityBike.AddMovementAlignsWithGroundContact( this, bCanFallOfEdges = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.RemoveMovementAlignsWithGroundContact(this);
	}
};