class UBasicGentlemanFitnessQueueSwitcherBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UFitnessSettings FitnessSettings;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UFitnessUserComponent FitnessComp;

	float BadFitnessTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FitnessSettings = UFitnessSettings::GetSettings(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(TargetComp.Target == nullptr)
			return;

		if(FitnessSettings.RespectPriorityTarget && BasicSettings.PriorityTarget != EHazePlayer::MAX)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player == nullptr)
			return;	

		float Score = FitnessComp.GetFitnessScore(Player);
		float OtherScore = FitnessComp.GetFitnessScore(Player.OtherPlayer);
		if(Score < FitnessSettings.OptimalThresholdMin && OtherScore > Score)
			BadFitnessTimer += DeltaTime;
		else
			BadFitnessTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(FitnessSettings.RespectPriorityTarget && BasicSettings.PriorityTarget != EHazePlayer::MAX)
			return false;

		// This behaviour is only built to work with players as targets
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player == nullptr)
			return false;

		if(BadFitnessTimer > 0)
			return BadFitnessTimer > 1;

		float Score = FitnessComp.GetFitnessScore(Player);
		float OtherScore = FitnessComp.GetFitnessScore(Player.OtherPlayer);
		if(OtherScore < FitnessSettings.OptimalThresholdMin && OtherScore < Score)
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
		{
			if (TargetComp.IsValidTarget(Game::Zoe))
				TargetComp.SetTarget(Game::Zoe);
		}
		else
		{
			if (TargetComp.IsValidTarget(Game::Mio))
				TargetComp.SetTarget(Game::Mio);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Never do this frequently
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(0.7, 1.2));
	}
}