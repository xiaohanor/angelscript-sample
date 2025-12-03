class UGravityBikeSplinePassengerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UGravityBikeSplinePassengerComponent PassengerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PassengerComp = UGravityBikeSplinePassengerComponent::Get(Player);
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
}