struct FDentistBossLookAtSelectedTargetActivationParams
{
	float SwitchDuration;
}

class UDentistBossLookAtSelectedTargetCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	UHazeActionQueueComponent ActionQueueComp;
	UDentistBossTargetComponent TargetComp;

	FDentistBossLookAtSelectedTargetActivationParams Params;

	FDentistBossHeadlightSettings StartSettings;

	FVector StartLocation;

	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);	
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossLookAtSelectedTargetActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.SwitchDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = TargetComp.LookTargetLocation; 
		StartSettings = Dentist.CurrentSpotlightSettings;

		DetachFromActionQueue();
		TargetComp.bOverrideLooking = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetComp.bOverrideLooking = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Params.SwitchDuration == 0)
		{
			TargetComp.LookAtTarget(TargetComp.Target.Get().ActorCenterLocation);
			return;
		}
		
		float Alpha = ActiveDuration / Params.SwitchDuration;

		if(Dentist.CurrentSpotlightSettings.LightColor != Settings.HasTargetSpotlightSettings.LightColor)
		{
			Dentist.CurrentSpotlightSettings.LerpSettings(StartSettings, Settings.HasTargetSpotlightSettings, Alpha);
			// Dentist.CurrentSpotlightSettings.ApplySettings(Dentist.HeadLightSpotlight, Dentist.GodrayComp, Dentist.LensFlareComp);
		}

		FVector NewTargetLocation = Math::Lerp(StartLocation, TargetComp.Target.Get().ActorCenterLocation, Alpha);
		TargetComp.LookAtTarget(NewTargetLocation);
	}
};