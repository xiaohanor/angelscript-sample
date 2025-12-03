class UGameShowArenaBombInteriorUpdaterCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);
	default TickGroup = EHazeTickGroup::AfterGameplay;
	AGameShowArenaBomb Bomb;

	const float MaxRotationsPerSecond = 4;
	const float MinRotationsPerSecond = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(Bomb.TimeUntilExplosion / Bomb.GetMaxExplodeTimerDuration());
		Alpha = 1 - Alpha;

		float RotationsPerSecond = Math::Lerp(MinRotationsPerSecond, MaxRotationsPerSecond, Alpha);
		float RotationSpeed = Math::RadiansToDegrees(TWO_PI * RotationsPerSecond);
		Bomb.InsideMesh.AddRelativeRotation(FRotator(0, RotationSpeed * DeltaTime, 0));
		Bomb.SimulatedInsideMesh.AddRelativeRotation(FRotator(0, RotationSpeed * DeltaTime, 0));
	}
};