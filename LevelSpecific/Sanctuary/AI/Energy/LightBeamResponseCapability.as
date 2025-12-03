
class ULightBeamResponseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LightBeamResponse");	
	default CapabilityTags.Add(n"EnergyResponse");	

	default DebugCategory = n"Energy";	

	ULightBeamResponseComponent ResponseComp;
	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ResponseComp = ULightBeamResponseComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ResponseComp.Beamers.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ResponseComp.Beamers.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: Get impulse from beam if that's still what we want.
		//FVector Impulse = ...
		//Owner.AddMovementImpulse(Impulse, n"LightBeamPush")

		// TODO: Continuous damage, needs better networking! 
		HealthComp.TakeDamage(0.05 * DeltaTime, EDamageType::Energy, ResponseComp.Beamers[0]);
	}
}