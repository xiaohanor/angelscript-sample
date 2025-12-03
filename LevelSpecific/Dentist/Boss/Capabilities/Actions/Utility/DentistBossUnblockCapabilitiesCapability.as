struct FDentistBossUnblockCapabilitiesActivationParams
{
	bool bUnblockTargetedPlayer = false;
	EHazeSelectPlayer PlayerSelection;
	FName CapabilityTag;
}

class UDentistBossUnblockCapabilitiesCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossUnblockCapabilitiesActivationParams Params;

	ADentistBoss Dentist;

	UDentistBossTargetComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossUnblockCapabilitiesActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TArray<AHazePlayerCharacter> PlayersToUnblock;
		if(Params.bUnblockTargetedPlayer)
		{
			PlayersToUnblock.Add(TargetComp.Target.Get());
		}
		else
		{
			if(Params.PlayerSelection == EHazeSelectPlayer::Mio)
				PlayersToUnblock.Add(Game::Mio);
			else if(Params.PlayerSelection == EHazeSelectPlayer::Zoe)
				PlayersToUnblock.Add(Game::Zoe);
			else if(Params.PlayerSelection == EHazeSelectPlayer::Both)
			{
				PlayersToUnblock.Add(Game::Mio);
				PlayersToUnblock.Add(Game::Zoe);
			}
		}

		for(auto Player : PlayersToUnblock)
		{
			Player.UnblockCapabilities(Params.CapabilityTag, Dentist);
			Dentist.CurrentCapabilityBlocks[Player].Blocks.RemoveSingleSwap(Params.CapabilityTag);
		}

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};