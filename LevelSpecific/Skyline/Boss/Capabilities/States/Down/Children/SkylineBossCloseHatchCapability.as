class USkylineBossCloseHatchCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossOpenRamps);

	USkylineBossDownComponent DownComp;
	USkylineBossHatchComponent HatchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		DownComp = USkylineBossDownComponent::Get(Boss);
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
//		if(ActiveDuration > SkylineBoss::Hatch::CloseDuration)
//			return true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HatchComp.CloseHatch();
		Boss.OnCloseHatch.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HatchComp.OnClosed();
		DownComp.bShouldRise = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
	}
};