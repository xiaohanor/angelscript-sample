class UDentistBossMalfunctioningEyesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	const float EyeMalfunctioningStartDelay = 0.4;
	const float NoiseMultiplier = 5.0;
	const float NoiseFrequency = 1.5;

	const float NoiseMultiplierWhenDrilled = 200.0;
	const float NoiseFrequencyWhenDrilled = 10.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentist.CurrentState == EDentistBossState::Defeated)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentist.CurrentState == EDentistBossState::Defeated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentist.EyeSpeed = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float RandomEyeSpeed;
		if(Dentist.FinisherProgress > 0.7)
			RandomEyeSpeed = Math::PerlinNoise1D(ActiveDuration * NoiseFrequencyWhenDrilled) * NoiseMultiplierWhenDrilled;
		else
			RandomEyeSpeed = Math::PerlinNoise1D(ActiveDuration * NoiseFrequency) * NoiseMultiplier;
		
		float TransitionAlpha = Math::Min(ActiveDuration / EyeMalfunctioningStartDelay, 1.0);
		Dentist.EyeSpeed = Math::Lerp(1.0, RandomEyeSpeed, TransitionAlpha);
	}
};