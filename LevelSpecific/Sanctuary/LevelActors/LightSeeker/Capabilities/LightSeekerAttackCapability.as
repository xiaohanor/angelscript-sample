class ULightSeekerAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightSeekerAttack");

	default TickGroup = EHazeTickGroup::Gameplay;

	ALightSeeker LightSeeker;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
//		if (!LightSeeker.HasActiveLightBirdTarget())
//			return false;

		// auto LightBirdUserComponent = ULightBirdUserComponent::Get(Game::Mio);
		// if (LightSeeker.Head.WorldLocation.Distance(LightBirdUserComponent.GetLightBirdLocation()) > LightSeeker.TargetOffset + 10.0)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (!LightSeeker.HasActiveLightBirdTarget())
//			return true;

		// if (ActiveDuration > LightSeeker.AttackTime)
		// 	return true;

//		if (LightSeeker.Head.WorldLocation.Distance(LightSeeker.LightBird.ActorLocation) > LightSeeker.TargetOffset + 10.0)
//			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LightSeeker.BlockCapabilities(n"LightSeekerMovement", this);		
		LightSeeker.bIsAttacking = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightSeeker.UnblockCapabilities(n"LightSeekerMovement", this);

		// if (LightSeeker.Head.WorldLocation.Distance(LightSeeker.LightBird.ActorLocation) < LightSeeker.TargetOffset + 10.0)
		// 	LightSeeker.LightBird.RequestDespawn();

		// LightSeeker.bIsAttacking = false;
	
		// LightSeeker.ConsumeForce();
		// LightSeeker.ConsumeTorque();
		// LightSeeker.Velocity = FVector::ZeroVector;
		// LightSeeker.AngularVelocity = FVector::ZeroVector;
		// LightSeeker.AttackAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	//	Debug::DrawDebugSphere(LightSeeker.Head.WorldLocation, 300.0, 12, FLinearColor::Red, 3.0, 0.0);
	}
};