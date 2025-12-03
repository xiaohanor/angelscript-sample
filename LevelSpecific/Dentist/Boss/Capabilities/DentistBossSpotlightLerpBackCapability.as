class UDentistBossSpotlightLerpSettingsCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;
	FDentistBossHeadlightSettings StartSettings;

	const float LerpDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if(TargetComp.Target.IsDefaultValue())
		// {
		// 	if(Dentist.HeadLightSpotlight.LightColor == Settings.HasNoTargetSpotlightSettings.LightColor)
		// 		return false;
		// }
		// else
		// {
		// 	if(Dentist.HeadLightSpotlight.LightColor == Settings.HasTargetSpotlightSettings.LightColor)
		// 		return false;
		// }
		

		return false;
		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(TargetComp.Target.IsDefaultValue())
		// {
		// 	if(Dentist.HeadLightSpotlight.LightColor == Settings.HasNoTargetSpotlightSettings.LightColor)
		// 		return true;
		// }
		// else
		// {
		// 	if(Dentist.HeadLightSpotlight.LightColor == Settings.HasTargetSpotlightSettings.LightColor)
		// 		return true;
		// }

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartSettings = Dentist.CurrentSpotlightSettings;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / LerpDuration;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		FDentistBossHeadlightSettings TargetSettings;
		if(TargetComp.Target.IsDefaultValue())
			TargetSettings = Settings.HasNoTargetSpotlightSettings;
		else
			TargetSettings = Settings.HasTargetSpotlightSettings;
		Dentist.CurrentSpotlightSettings.LerpSettings(StartSettings, TargetSettings, Alpha);
		// Dentist.CurrentSpotlightSettings.ApplySettings(Dentist.HeadLightSpotlight, Dentist.GodrayComp, Dentist.LensFlareComp);
	}
};