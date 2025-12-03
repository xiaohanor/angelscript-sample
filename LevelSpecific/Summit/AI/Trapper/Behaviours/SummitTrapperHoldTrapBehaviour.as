class USummitTrapperHoldTrapBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGentlemanCostComponent GentCostComp;
	USummitTrapperTrapComponent TrapComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		TrapComp = USummitTrapperTrapComponent::GetOrCreate(Owner);
		TrapComp.OnReleasePlayer.AddUFunction(this, n"OnReleasePlayer");
	}

	UFUNCTION()
	private void OnReleasePlayer()
	{
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(TrapComp.TrappedDragon == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.CancelPendingReleaseToken(TrapComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.PendingReleaseToken(TrapComp);
	}
}