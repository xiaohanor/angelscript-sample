// Should be placed before other target finding behaviours in compounds
class USummitTeenDragonFindPriorityTargetBehaviour : UBasicBehaviour
{
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
		AHazePlayerCharacter Player;

		if(BasicSettings.PriorityTarget == EHazePlayer::Mio)
			Player = Game::Mio;

		if(BasicSettings.PriorityTarget == EHazePlayer::Zoe)
			Player = Game::Zoe;

		auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if(DragonComp != nullptr)
			TargetComp.SetTarget(Player);
	}
}