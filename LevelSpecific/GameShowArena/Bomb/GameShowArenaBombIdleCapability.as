class UGameShowArenaBombIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	AGameShowArenaBomb Bomb;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Frozen)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Frozen)
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
		float Alpha = (Math::Sin(Time::GameTimeSeconds * 5) + 1) * 0.5;
		Alpha = Math::SmoothStep(0, 1, Alpha);
		Bomb.UpdateFillMaterial(Math::Lerp(1, 0, Alpha), FVector(1, 5, 1));
	}
};