struct FDentistBossBlockCapabilitiesActivationParams
{
	bool bBlockTargetedPlayer = false;
	EHazeSelectPlayer PlayerSelection;
	FName CapabilityTag;
}

class UDentistBossBlockCapabilitiesCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossBlockCapabilitiesActivationParams Params;

	ADentistBoss Dentist;

	
	UDentistBossTargetComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

				TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossBlockCapabilitiesActivationParams InParams)
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
		TArray<AHazePlayerCharacter> PlayersToBlock;
		if(Params.bBlockTargetedPlayer)
		{
			PlayersToBlock.Add(TargetComp.Target.Get());
		}
		else
		{
			if(Params.PlayerSelection == EHazeSelectPlayer::Mio)
				PlayersToBlock.Add(Game::Mio);
			else if(Params.PlayerSelection == EHazeSelectPlayer::Zoe)
				PlayersToBlock.Add(Game::Zoe);
			else if(Params.PlayerSelection == EHazeSelectPlayer::Both)
			{
				PlayersToBlock.Add(Game::Mio);
				PlayersToBlock.Add(Game::Zoe);
			}
		}

		for(auto Player : PlayersToBlock)
		{
			Player.BlockCapabilities(Params.CapabilityTag, Dentist);
			Dentist.CurrentCapabilityBlocks[Player].Blocks.Add(Params.CapabilityTag);
		}

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};