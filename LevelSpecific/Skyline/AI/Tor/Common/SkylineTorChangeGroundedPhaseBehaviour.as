class USkylineTorChangeGroundedPhaseBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Attack");
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorSettings Settings;

	int Activations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!HoldHammerComp.bAttached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Activations++;
		if(Activations <= 1 || PhaseComp.SubPhase == ESkylineTorSubPhase::GroundedShort)
		{
			DeactivateBehaviour();
			return;
		}

		PhaseComp.SetSubPhase(ESkylineTorSubPhase::GroundedShort);
	}

}
