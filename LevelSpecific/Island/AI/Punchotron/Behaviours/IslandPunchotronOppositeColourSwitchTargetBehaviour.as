class UIslandPunchotronOppositeColourSwitchTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandForceFieldComponent ForceFieldComp;

	private bool bShouldSwitch = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		ForceFieldComp.OnSwitchedCurrentType.AddUFunction(this, n"OnSwitchedType");
	}

	UFUNCTION()
	private void OnSwitchedType(EIslandForceFieldType NewType)
	{
		// prepare for activation
		bShouldSwitch = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
	
		if (ForceFieldComp == nullptr)
			return false;

		if (ForceFieldComp.IsDepleted())
			return false;

		// This behaviour only switches targets, it does not find new ones.
		if (TargetComp.Target == nullptr)
			return false;

		if (!bShouldSwitch)
			return false;
		
		if (IslandForceField::GetPlayerForceFieldType(Cast<AHazePlayerCharacter>(TargetComp.Target)) != ForceFieldComp.CurrentType)
			return false;
		
		// Don't switch target in the middle of an ongoing attack
		if (Owner.IsAnyCapabilityActive(BasicAITags::Attack))
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
		bShouldSwitch = false;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (IslandForceField::GetPlayerForceFieldType(Player) != ForceFieldComp.CurrentType)
			{
				TargetComp.SetTarget(Player);
				break;
			}
		}
	}
}
