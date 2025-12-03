struct FDentistBossChairRemovalActivationParams
{
	EHazeSelectPlayer RemovalSelection;
}

class UDentistBossChairRemovalCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	FDentistBossChairRemovalActivationParams Params;

	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossChairRemovalActivationParams InParams)
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
		TArray<AHazePlayerCharacter> PlayersChairsToRemove;
		if(Params.RemovalSelection == EHazeSelectPlayer::Mio)
			PlayersChairsToRemove.Add(Game::Mio);
		else if(Params.RemovalSelection == EHazeSelectPlayer::Zoe)
			PlayersChairsToRemove.Add(Game::Zoe);
		else if(Params.RemovalSelection == EHazeSelectPlayer::Both)
		{
			PlayersChairsToRemove.Add(Game::Mio);
			PlayersChairsToRemove.Add(Game::Zoe);
		}

		for(auto Player : PlayersChairsToRemove)
		{
			ADentistBossTool Tool;
			if(Player.IsMio())
				Tool = Dentist.Tools[EDentistBossTool::MioChair];
			else
				Tool = Dentist.Tools[EDentistBossTool::ZoeChair];

			if(!Tool.bActive)
				continue;

			FDentistBossEffectHandlerOnChairDestroyedByEscapingParams EffectParams;
			EffectParams.Chair = Cast<ADentistBossToolChair>(Tool);
			UDentistBossEffectHandler::Trigger_OnChairDestroyedByEscaping(Dentist, EffectParams);
			Tool.Deactivate();
		}

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};