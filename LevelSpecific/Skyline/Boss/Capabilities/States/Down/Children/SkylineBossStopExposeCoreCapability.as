class USkylineBossStopExposeCoreCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossExposeCore);

	USkylineBossCoreComponent CoreComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		CoreComp = Boss.CoreComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.HatchComponent.GetState() != ESkylineBossHatchState::Closed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CoreComp.StopExposeCore();
		Boss.Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DisableSkylineBossArenaPickups(n"RampPickup");
		EnableSkylineBossArenaPickups();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};	