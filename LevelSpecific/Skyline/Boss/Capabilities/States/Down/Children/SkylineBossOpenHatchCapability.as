class USkylineBossOpenHatchCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossOpenRamps);

	USkylineBossHatchComponent HatchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		HatchComp = Boss.HatchComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > SkylineBoss::Hatch::OpenDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HatchComp.OpenHatch();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HatchComp.OnOpened();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
	}
};