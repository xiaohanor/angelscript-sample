class UEnforcerHoveringCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Jetpack");
	default CapabilityTags.Add(n"Hovering");

	UBasicAIHealthComponent HealthComp;
	UEnforcerJetpackComponent JetpackComp;
	UBasicAIDestinationComponent DestinationComp;
	UEnforcerHoveringSettings Settings;
	bool bJetpackIgnited; 
	float BobbingBaseTime;
	float BobbingInterval;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		JetpackComp = UEnforcerJetpackComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		Settings = UEnforcerHoveringSettings::GetSettings(Owner);
		BobbingInterval = Math::RandRange(Settings.BobbingMinInterval, Settings.BobbingMaxInterval);
		BobbingInterval = Math::Max(0.1, BobbingInterval);
		BobbingBaseTime = Time::GameTimeSeconds + Math::RandRange(0.0, BobbingInterval);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Hover until dead for now
		if (HealthComp.IsDead())
			return false;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		JetpackComp.StartJetpack();
		bJetpackIgnited = false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
		JetpackComp.StopJetpack();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bJetpackIgnited && (ActiveDuration > 0.5))
		{
			bJetpackIgnited = true;
			UEnforcerJetpackEffectHandler::Trigger_JetpackTravel(Owner);
		}

		// So we can tweak bobbing in real time
		if (!Math::IsWithin(BobbingInterval, Settings.BobbingMinInterval, Settings.BobbingMaxInterval))
			BobbingInterval = Math::Max(0.1, Math::RandRange(Settings.BobbingMinInterval, Settings.BobbingMaxInterval));

		float BobbingSin = Math::Sin((Time::GameTimeSeconds - BobbingBaseTime) * 2.0 * PI / BobbingInterval); 
		float BobbingAmplitude = Settings.BobbingAmplitude * 0.5 * (2.0 + Math::Sin((Time::GameTimeSeconds - BobbingBaseTime) * 1.73 / BobbingInterval)); // 0.5..1.5
		DestinationComp.AddCustomAcceleration(Owner.ActorUpVector * (BobbingAmplitude / BobbingInterval) * BobbingSin);
	}
}

