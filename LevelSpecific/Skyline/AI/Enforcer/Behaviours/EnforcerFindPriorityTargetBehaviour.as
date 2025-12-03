// Should be placed before other target finding behaviours in compounds
class UEnforcerFindPriorityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIControlSideSwitchComponent ControlSideSwitchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ControlSideSwitchComp = UBasicAIControlSideSwitchComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(BasicSettings.PriorityTarget == EHazePlayer::MAX)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AHazeActor PrevTarget = TargetComp.Target;

		if(BasicSettings.PriorityTarget == EHazePlayer::Mio)
			TargetComp.SetTarget(Game::Mio);

		if(BasicSettings.PriorityTarget == EHazePlayer::Zoe)
			TargetComp.SetTarget(Game::Zoe);	

		if (TargetComp.Target != PrevTarget)
			CrumbChangeTarget(TargetComp.Target);
		Cooldown.Set(1.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbChangeTarget(AHazeActor Target)
	{
		// Match control side with target
		ControlSideSwitchComp.WantedController = Target;

		// Since this may trigger a control side switch we should make sure cooldown is set on both sides
		Cooldown.Set(1.0);
	}
}