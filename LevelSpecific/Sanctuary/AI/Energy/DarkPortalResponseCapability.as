
class UDarkPortalResponseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LightBeamResponse");	
	default CapabilityTags.Add(n"EnergyResponse");	

	default DebugCategory = n"Energy";	

	UDarkPortalResponseComponent ResponseComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ResponseComp = UDarkPortalResponseComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ResponseComp.Grabs.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ResponseComp.Grabs.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: Get impulse from dark portal if that's still what we want.
		//FVector Impulse = ...
		//Owner.AddMovementImpulse(Impulse, n"LightBeamPush")
	}
}