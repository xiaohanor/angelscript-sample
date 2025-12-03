class UBigCrackBirdNestLocationCorrectionCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	float StartTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Bird.GetState() != ETundraCrackBirdState::PuttingDown)
			return false;

		if(Bird.TargetNest == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Bird.GetState() != ETundraCrackBirdState::PuttingDown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTime = Bird.InteractingPlayer.IsMio() ? 1.5 : 0.7;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > StartTime)
			Owner.SetActorLocation(Math::VInterpTo(Owner.ActorLocation, Bird.TargetNest.ActorLocation + Bird.NestRelativeLocation, DeltaTime, 20));
	}
};