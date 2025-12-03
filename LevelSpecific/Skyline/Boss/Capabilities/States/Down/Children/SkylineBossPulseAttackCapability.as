class USkylineBossPulseAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossPulseAttack);

	USkylineBossPulseAttackComponent PulseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		PulseComp = USkylineBossPulseAttackComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boss.CoreComponent.IsCoreExposed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > PulseComp.PulseChargeupTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PulseComp.CreatePulse();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Boss.CoreHazeSphere.SetOpacityValue(PulseComp.HazeSphereOpacityCurve.GetFloatValue(ActiveDuration / PulseComp.PulseChargeupTime));
	}
};