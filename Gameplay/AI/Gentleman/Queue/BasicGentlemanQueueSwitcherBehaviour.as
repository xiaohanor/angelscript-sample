// Behaviour to switch targets to balance out the number of opponents each player has.
class UBasicGentlemanQueueSwitcherBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UGentlemanCostQueueComponent GentCostQueueComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(BasicSettings.PriorityTarget != EHazePlayer::MAX)
			return false;

		// This behaviour is only built to work with players as targets
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player == nullptr)
			return false;

		auto GentComp = UGentlemanComponent::GetOrCreate(Player);
		auto OtherGentComp = UGentlemanComponent::GetOrCreate(Player.OtherPlayer);
		int OpponentsNum = GentComp.GetNumOpponents();
		int OtherOpponentsNum = OtherGentComp.GetNumOpponents();
		int HalfOfOpponentsNum = Math::FloorToInt((OpponentsNum + OtherOpponentsNum) / 2.0);

		// The other target already has half or close to half of the opponents, so we shouldn't switch
		if(OtherOpponentsNum >= HalfOfOpponentsNum)
			return false;

		int Position = GentCostQueueComp.GetQueuePosition();
		int OtherSize = GentCostQueueComp.GetOtherQueueSize();

		// We only compare position and size if we have valid values
		if(Position != -1 && OtherSize != -1)
		{
			// If our position is lower or equal to the size of the other queue, so we would get a worse or equal position by switching
			if(Position <= OtherSize)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		if(TargetComp.Target == Game::Mio)
			TargetComp.SetTarget(Game::Zoe);
		else
			TargetComp.SetTarget(Game::Mio);

		// Wait with this a while, we don't want to flood network with set target crumbs
		Cooldown.Set(BasicSettings.GentlemanQueueSwitchingCooldown);
	}
}