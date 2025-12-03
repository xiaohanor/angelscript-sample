// Should be placed before other target finding behaviours in compounds
class UEnforcerPrioritySwitchTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AHazeCharacter CurrentPriorityTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		if (BasicSettings.PriorityTarget != EHazePlayer::MAX)
			CurrentPriorityTarget = BasicSettings.PriorityTarget == EHazePlayer::Mio ? Game::Mio : Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (CurrentPriorityTarget == nullptr)
			return false;

		UGentlemanComponent GentleComp = UGentlemanComponent::GetOrCreate(CurrentPriorityTarget);
		int NumOpponents = GentleComp.GetNumOpponents();
		if (NumOpponents > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		TargetComp.SetTarget(CurrentPriorityTarget);
	}
}