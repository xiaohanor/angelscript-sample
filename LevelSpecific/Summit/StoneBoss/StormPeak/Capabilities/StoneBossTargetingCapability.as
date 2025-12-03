class UStoneBossTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBossPeak StoneBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBoss = Cast<AStoneBossPeak>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StoneBoss.State != EStoneBossPeakPhase::Vulnerable)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StoneBoss.State != EStoneBossPeakPhase::Vulnerable)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLoc = Game::Zoe.ViewLocation;
		FVector Dir = (TargetLoc - StoneBoss.ActorLocation).GetSafeNormal();
		Dir = Dir.ConstrainToPlane(FVector::UpVector);
		StoneBoss.ActorRotation = Dir.Rotation();
	}
};