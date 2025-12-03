class UIslandPunchotronSwitchTargetOnDeathBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandForceFieldComponent ForceFieldComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandPunchotronOnDeathSwitchTargetBehaviourActivationParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;

		// This behaviour only switches targets, it does not find new ones.
		if (TargetComp.Target == nullptr)
			return false;

		// Check if alive and enabled
		if (TargetComp.HasValidTarget())
			return false;
		
		// Switch to other player
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Skip current target
			if (Player == TargetComp.Target)
				continue;

			// Is other player valid
			if (!TargetComp.IsValidTarget(Player))
				return false;
			
			Params.NewTarget = Player;
		}		

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
	void OnActivated(FIslandPunchotronOnDeathSwitchTargetBehaviourActivationParams Params)
	{
		Super::OnActivated();
		TargetComp.SetTarget(Params.NewTarget);
	}
}

struct FIslandPunchotronOnDeathSwitchTargetBehaviourActivationParams
{
	AHazePlayerCharacter NewTarget;
}