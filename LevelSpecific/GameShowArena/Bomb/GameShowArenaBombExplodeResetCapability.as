class UGameShowArenaBombExplodeResetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	AGameShowArenaBomb Bomb;

	FHazeAcceleratedFloat AccExplodeTimer;

	float ResetDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Bomb.bResetExplodeTimer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > ResetDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccExplodeTimer.SnapTo(Bomb.TimeUntilExplosion);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bomb.bResetExplodeTimer = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccExplodeTimer.AccelerateToWithStop(Bomb.GetMaxExplodeTimerDuration(), ResetDuration, DeltaTime, 0.01 * Bomb.GetMaxExplodeTimerDuration());
		Bomb.TimeUntilExplosion = AccExplodeTimer.Value;
	}
};