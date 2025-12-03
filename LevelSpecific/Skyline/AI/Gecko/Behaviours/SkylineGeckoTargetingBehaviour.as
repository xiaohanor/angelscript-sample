class USkylineGeckoTargetingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AHazePlayerCharacter LastTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		LastTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AHazePlayerCharacter Target = GetBestTarget();
		if (TargetComp.IsValidTarget(Target))
		{
			LastTarget = Target;
			TargetComp.SetTarget(LastTarget);
		}
		Cooldown.Set(0.5);
	}

	AHazePlayerCharacter GetBestTarget()
	{
		// Use aggro target, if any
		if (TargetComp.IsValidTarget(TargetComp.AggroTarget))
			return Cast<AHazePlayerCharacter>(TargetComp.AggroTarget);

		// If one player is invalid, use the other
		if (!TargetComp.IsValidTarget(Game::Mio))
			return Game::Zoe;
		if (!TargetComp.IsValidTarget(Game::Zoe))
			return Game::Mio;

		// Target the player with least number of opponents
		UGentlemanComponent MioGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Mio);
		UGentlemanComponent ZoeGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
		int NumMioOpponents = MioGentlemanComp.GetNumOtherOpponents(Owner);
		int NumZoeOpponents = ZoeGentlemanComp.GetNumOtherOpponents(Owner);
		if (NumMioOpponents < NumZoeOpponents)
			return Game::Mio;
		if (NumZoeOpponents < NumMioOpponents)
			return Game::Zoe;

		// Equal number of opponents. Start with Mio, then alternate targets	
		if (LastTarget == nullptr)
			return Game::Mio;
		return LastTarget.OtherPlayer;
	}
}
