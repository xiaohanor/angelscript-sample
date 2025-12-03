class USolarFlareWeightedGrapplePlatformCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SolarFlareWeightedGrapplePlatformCapability");

	default TickGroup = EHazeTickGroup::Input;
	
	ASolarFlareWeightedGrapplePlatform Platform; 
	UFauxPhysicsForceComponent ForceComp;

	float CurrentForce;
	float InterpSpeed = 1500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASolarFlareWeightedGrapplePlatform>(Owner);
		ForceComp = UFauxPhysicsForceComponent::Get(Owner);
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
		CurrentForce = Platform.StartForceAmount;
		Platform.TargetSpeed = Platform.StartForceAmount;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > Platform.DelayTime)
			Platform.TargetSpeed = Math::FInterpConstantTo(Platform.TargetSpeed, Platform.StartForceAmount, DeltaTime, InterpSpeed);
		
		CurrentForce = Math::FInterpTo(CurrentForce, Platform.TargetSpeed, DeltaTime, 0.5);
		ForceComp.Force = FVector(0.0, 0.0, CurrentForce); 
		PrintToScreen("CurrentForce: " + CurrentForce);
		PrintToScreen("ForceComp.Force: " + ForceComp.Force);
	}
};