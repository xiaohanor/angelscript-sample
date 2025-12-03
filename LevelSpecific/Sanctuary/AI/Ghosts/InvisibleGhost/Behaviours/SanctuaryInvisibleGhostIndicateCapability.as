class USanctuaryInvisibleGhostIndicateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryInvisibleGhostSettings InvisibleGhostSettings;
	USanctuaryInvisibleGhostVisibilityComp VisibilityComp;
	float IndicateTime;

	AAISanctuaryInvisibleGhost Ghost;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InvisibleGhostSettings = USanctuaryInvisibleGhostSettings::GetSettings(Owner);
		VisibilityComp = USanctuaryInvisibleGhostVisibilityComp::Get(Owner);		
		VisibilityComp.OnHide.AddUFunction(this, n"OnHide");
		IndicateTime = Time::GetGameTimeSeconds();
		Ghost = Cast<AAISanctuaryInvisibleGhost>(Owner);
	}

	UFUNCTION()
	private void OnHide()
	{
		IndicateTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Time::GetGameTimeSince(IndicateTime) < InvisibleGhostSettings.IndicateInterval)
			return false;
		if(VisibilityComp.bVisible)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > InvisibleGhostSettings.IndicateDuration + InvisibleGhostSettings.IndicateWait)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		VisibilityComp.StartIndicate();

		Ghost.Mesh.SetVisibility(true, false);
		for(int i = 0; i < Ghost.Mesh.NumMaterials; ++i)
		{
			Ghost.Mesh.SetMaterial(i, Ghost.IndicatorMaterial);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		VisibilityComp.StopIndicate();
		IndicateTime = Time::GetGameTimeSeconds();

		Ghost.Mesh.SetVisibility(false, true);
		Ghost.ResetMaterial();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float HalfDuration = InvisibleGhostSettings.IndicateDuration / 2;

		float Alpha;
		if(ActiveDuration > HalfDuration)
			Alpha = Math::Clamp((InvisibleGhostSettings.IndicateDuration - ActiveDuration) / HalfDuration, 0, 1);
		else
			Alpha = Math::Clamp(ActiveDuration / HalfDuration, 0, 1);

		if(Alpha == 0 && ActiveDuration > InvisibleGhostSettings.IndicateDuration)
			Ghost.Mesh.SetVisibility(false, true);

		Ghost.Mesh.SetScalarParameterValueOnMaterials(n"Opacity", Alpha);
	}
}