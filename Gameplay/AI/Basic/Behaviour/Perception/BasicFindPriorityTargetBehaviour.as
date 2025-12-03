// Should be placed before other target finding behaviours in compounds
class UBasicFindPriorityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

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

		if(BasicSettings.PriorityTarget == EHazePlayer::Mio)
			TargetComp.SetTarget(Game::Mio);

		if(BasicSettings.PriorityTarget == EHazePlayer::Zoe)
			TargetComp.SetTarget(Game::Zoe);	
	}
}