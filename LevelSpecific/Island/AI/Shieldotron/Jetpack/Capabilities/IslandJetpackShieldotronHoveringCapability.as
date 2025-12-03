class UIslandJetpackShieldotronHoveringCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Jetpack");
	default CapabilityTags.Add(n"Hovering");

	UBasicAIHealthComponent HealthComp;
	UBasicAIDestinationComponent DestinationComp;
	UIslandJetpackShieldotronComponent JetpackComp;

	AAIIslandJetpackShieldotron JetpackShieldotron;

	bool bJetpackIgnited; 
	float BobbingBaseTime;
	float BobbingInterval;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		JetpackComp = UIslandJetpackShieldotronComponent::Get(Owner);		
		BobbingInterval = Math::RandRange(1.5, 2.5);
		BobbingBaseTime = Time::GameTimeSeconds + Math::RandRange(0.0, BobbingInterval);
		JetpackShieldotron = Cast<AAIIslandJetpackShieldotron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Hover until dead for now
		if (HealthComp.IsDead())
			return false;
		if (!JetpackComp.IsInAir())
			return false;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.IsDead())
			return true;
		if (!JetpackComp.IsInAir())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//UIslandShieldotronJetpackEffectHandler::Trigger_JetpackStart(Owner, FIslandJetpackShieldotronJetParams(JetpackShieldotron.JetpackVFX));
		bJetpackIgnited = false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//UIslandShieldotronJetpackEffectHandler::Trigger_JetpackEnd(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bJetpackIgnited && (ActiveDuration > 0.5))
		{
			bJetpackIgnited = true;
			//UIslandShieldotronJetpackEffectHandler::Trigger_JetpackTraversal(Owner, FIslandJetpackShieldotronJetParams(JetpackShieldotron.JetpackVFX));
		}

		// So we can tweak bobbing in real time
		if (!Math::IsWithin(BobbingInterval, 1.5, 2.5))
			BobbingInterval = Math::Max(0.1, Math::RandRange(1.5, 2.5));

		float BobbingSin = Math::Sin((Time::GameTimeSeconds - BobbingBaseTime) * 2.0 * PI / BobbingInterval); 
		float BobbingAmplitude = 75 * 0.5 * (2.0 + Math::Sin((Time::GameTimeSeconds - BobbingBaseTime) * 1.73 / BobbingInterval));
		DestinationComp.AddCustomAcceleration(Owner.ActorUpVector * (BobbingAmplitude / BobbingInterval) * BobbingSin);
	}
}

