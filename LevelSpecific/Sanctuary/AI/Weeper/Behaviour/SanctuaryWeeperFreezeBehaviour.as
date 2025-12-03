
class USanctuaryWeeperFreezeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USanctuaryWeeperSettings WeeperSettings;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryWeeperViewComponent ViewComp;
	USanctuaryWeeperFreezeComponent FreezeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WeeperSettings = USanctuaryWeeperSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		ViewComp = USanctuaryWeeperViewComponent::Get(Owner);
		FreezeComp = USanctuaryWeeperFreezeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!FreezeComp.bPermanentFreeze)
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		// if (!ViewComp.ShouldFreeze())
		// 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!FreezeComp.bPermanentFreeze)
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		// if (!ViewComp.ShouldFreeze())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		MoveComp.Reset();
		AnimComp.RequestFeature(SanctuaryWeeperTags::Freeze, EBasicBehaviourPriority::Medium, this);
		FreezeComp.Freeze();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		FreezeComp.Unfreeze();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}

