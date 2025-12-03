class USkylineGeckoQueueSwitcher : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

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
		auto AreaComp = USkylineGeckoAreaPlayerComponent::GetOrCreate(TargetComp.Target);
		if(AreaComp.SameArea(Owner))
			return false;

		// This behaviour is only built to work with players as targets
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player == nullptr)
			return false;

		auto GentComp = UGentlemanComponent::GetOrCreate(Player);
		auto OtherGentComp = UGentlemanComponent::GetOrCreate(Player.OtherPlayer);
		int OpponentsNum = GentComp.GetNumOtherOpponents(Owner);
		int OtherOpponentsNum = OtherGentComp.GetNumOtherOpponents(Owner);
		int HalfOfOpponentsNum = Math::FloorToInt((OpponentsNum + OtherOpponentsNum) / 2.0);

		// The other target already has half or close to half of the opponents, so we shouldn't switch
		if(OtherOpponentsNum >= HalfOfOpponentsNum)
			return false;

		int Position = GentCostQueueComp.GetQueuePosition();
		int OtherSize = GentCostQueueComp.GetOtherQueueSize();

		// Can't compare if getting invalid queue sizes
		if(Position == -1)
			return false;
		if(OtherSize == -1)
			return false;

		// Our position is lower or equal ton the size of the other queue, so we would get a worse or equal position by switching
		if(Position <= OtherSize)
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
		if(TargetComp.Target == Game::Mio)
			TargetComp.SetTarget(Game::Zoe);
		else
			TargetComp.SetTarget(Game::Mio);
	}
}