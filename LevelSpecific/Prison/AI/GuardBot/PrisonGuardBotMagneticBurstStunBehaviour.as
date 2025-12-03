class UPrisonGuardBotMagneticBurstStunBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Animation); 

	UMagneticFieldResponseComponent MagneticResponseComp; 
	UPrisonGuardBotSettings BotSettings;

	FVector BurstDir = FVector::ZeroVector;
	float BurstTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MagneticResponseComp = UMagneticFieldResponseComponent::Get(Owner);
		MagneticResponseComp.OnBurst.AddUFunction(this, n"OnBurst"); 	
		BotSettings = UPrisonGuardBotSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnBurst(FMagneticFieldData Data)
	{
		BurstDir = Data.GetAverageForceDirection();
		BurstTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (BurstDir.IsZero())
			return false;

		if (Time::GetGameTimeSince(BurstTime) > 0.5)
			return false;
	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > BotSettings.MagneticBurstStunTime)
			return true;
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.AddMovementImpulse(BurstDir * BotSettings.MagneticBurstStunForce);
	}
}