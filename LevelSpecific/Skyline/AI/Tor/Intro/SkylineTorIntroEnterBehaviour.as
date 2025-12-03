class  USkylineTorIntroEnterBehaviour : UBasicBehaviour
{
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorHoldHammerComponent HoldHammerComp;

	bool bCompleted;
	bool bEntered;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bEntered && HoldHammerComp.Hammer.VolleyComp.bLanded)
		{
			bEntered = true;
			PhaseComp.SetSubPhase(ESkylineTorSubPhase::EntryEnter);
			TargetComp.SetTarget(nullptr);
		}
	}
}
