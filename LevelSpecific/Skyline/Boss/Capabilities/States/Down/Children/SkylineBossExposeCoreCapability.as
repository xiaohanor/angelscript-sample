class USkylineBossExposeCoreCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossExposeCore);

	USkylineBossCoreComponent CoreComp;
	bool bPickupsEnabled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		CoreComp = Boss.CoreComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.IsPhaseActive(ESkylineBossPhase::First) && Boss.HealthComponent.GetHealthFraction() <= 0.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreenScaled("ExposeCore!", 3.0, FLinearColor::Green, 3.0);
		CoreComp.StartExposeCore();
		Boss.Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
//		EnableSkylineBossArenaPickups(n"RampPickup");
		DisableSkylineBossArenaPickups();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CoreComp.StopExposeCore();
		Boss.Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DisableSkylineBossArenaPickups(n"RampPickup");
		EnableSkylineBossArenaPickups();
		bPickupsEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bPickupsEnabled && ActiveDuration > 2.0)
		{
			EnableSkylineBossArenaPickups(n"RampPickup");
			bPickupsEnabled = true;
		}
	}
};