struct FSkylineTorHammerStolenIdleCapabilityParams
{
	UGravityWhipUserComponent WhipUser;
}

class USkylineTorHammerStolenIdleCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USkylineTorHammerStolenComponent StolenComp;
	UGravityWhipUserComponent WhipUser;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		StolenComp = USkylineTorHammerStolenComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineTorHammerStolenIdleCapabilityParams& OutParams) const
	{
		if(!StolenComp.bIdle)
			return false;
		if(StolenComp.WhipUserComp == nullptr)
			return false;
		OutParams.WhipUser = StolenComp.WhipUserComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!StolenComp.bIdle)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineTorHammerStolenIdleCapabilityParams Params)
	{
		WhipUser = Params.WhipUser;
		AccLocation.SnapTo(Owner.ActorLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector IdleLocation = WhipUser.Owner.ActorLocation + WhipUser.Owner.ActorRightVector * 100 + FVector::UpVector * 150 + WhipUser.Owner.ActorForwardVector * 100;

		float MinStiffness = 50;
		float Stiffness = IdleLocation.Distance(Owner.ActorLocation) < 250 ? MinStiffness : Math::Clamp(IdleLocation.Distance(Owner.ActorLocation), MinStiffness, 150);

		AccLocation.SpringTo(IdleLocation, Stiffness, 0.5, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;

		AccRotation.SpringTo(WhipUser.Owner.ActorForwardVector.Rotation(), Stiffness, 0.5, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;

		HammerComp.HoldHammerComp.Hammer.FauxRotateComp.ApplyForce(HammerComp.HoldHammerComp.Hammer.ActorLocation + FVector::UpVector * 100, WhipUser.Owner.ActorVelocity * 4);
	}
}