class USkylineGeckoRetarget : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	AAISkylineGecko Gecko;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Gecko = Cast<AAISkylineGecko>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(TargetComp.HasValidTarget())
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
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Gecko.AggroTarget != nullptr)
		{
			// Bind function to switch back to aggro target when player respawns
			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Gecko.AggroTarget);
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnAggroTargetRespawned");
		}
		if ((PlayerTarget != nullptr) && TargetComp.IsValidTarget(PlayerTarget.OtherPlayer))
			TargetComp.SetTarget(PlayerTarget.OtherPlayer);

		// Never spam this or network messages will go through the roof!
		// We should probably not run retargeting as a behaviour at all but 
		// instead send a few crumb messages on the player that switches 
		// target locally for a whole batch of geckos.
		Cooldown.Set(Math::RandRange(0.3, 0.7));
	}

	UFUNCTION()
	private void OnAggroTargetRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if (RespawnedPlayer != Gecko.AggroTarget)
			return;
		
		// Only switch target if the number of opponents is balancing out
		UGentlemanComponent MioGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Mio);
		UGentlemanComponent ZoeGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
		int NumMioOpponents = MioGentlemanComp.GetNumOtherOpponents(Owner);
		int NumZoeOpponents = ZoeGentlemanComp.GetNumOtherOpponents(Owner);
		if (Gecko.AggroTarget == Game::Mio && NumMioOpponents < NumZoeOpponents)
			TargetComp.SetTarget(RespawnedPlayer);
		else if (Gecko.AggroTarget == Game::Zoe && NumZoeOpponents < NumMioOpponents)
			TargetComp.SetTarget(RespawnedPlayer);
	}
}