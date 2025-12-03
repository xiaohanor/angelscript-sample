struct FDentistBossChairRestraintActivationParams
{
	EHazeSelectPlayer RestraintSelection;
	bool bDeactivateChairOnCompleted = true;
}

class UDentistBossChairRestraintCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossChairRestraintActivationParams Params;
	
	ADentistBoss Dentist;
	UDentistBossSettings Settings;
	TArray<AHazePlayerCharacter> ActivatedPlayers;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossChairRestraintActivationParams InParams)
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
		ActivatedPlayers.Reset();

		if(Params.RestraintSelection == EHazeSelectPlayer::Mio)
			ActivatedPlayers.Add(Game::Mio);
		else if(Params.RestraintSelection == EHazeSelectPlayer::Zoe)
			ActivatedPlayers.Add(Game::Zoe);
		else if(Params.RestraintSelection == EHazeSelectPlayer::Both)
		{
			ActivatedPlayers.Add(Game::Mio);
			ActivatedPlayers.Add(Game::Zoe);
		}

		for(auto Player : ActivatedPlayers)
		{
			ADentistBossTool Tool;
			if(Player.IsMio())
				Tool = Dentist.Tools[EDentistBossTool::MioChair];
			else
				Tool = Dentist.Tools[EDentistBossTool::ZoeChair];
			ADentistBossToolChair Chair = Cast<ADentistBossToolChair>(Tool);

			if(Settings.bChairStickWiggleEscape)
			{
				FStickWiggleSettings WiggleSettings = Settings.ChairStickWiggleSettings;
				WiggleSettings.WidgetAttachComponent = Chair.Root;
				WiggleSettings.WidgetPositionOffset = Settings.ChairWiggleTutorialPromptOffset;
				if(Player.IsMio())
					Player.StartStickWiggle(WiggleSettings, Dentist, FOnStickWiggleCompleted(this, n"OnMioWiggleCompleted"));
				else
					Player.StartStickWiggle(WiggleSettings, Dentist, FOnStickWiggleCompleted(this, n"OnZoeWiggleCompleted"));
			}
			else
			{
				if(Player.IsMio())
					Player.StartButtonMash(Settings.ChairButtonMashSettings, Dentist, FOnButtonMashCompleted(this, n"OnMioWiggleCompleted"));
				else
					Player.StartButtonMash(Settings.ChairButtonMashSettings, Dentist, FOnButtonMashCompleted(this, n"OnZoeWiggleCompleted"));
			}
			
			
			Chair.RestrainedPlayer.Set(Player);
			Player.ActorLocation = Chair.PlayerAttachLocation.WorldLocation;
			Player.ActorRotation = Chair.PlayerAttachLocation.WorldRotation;
			UDentistToothPlayerComponent ToothComp = UDentistToothPlayerComponent::Get(Player);
			ToothComp.SetMeshWorldRotation(Player.ActorQuat, this);
			Tool.Activate();
		}

		Dentist.bLeftPlayerEscapedChair = false;
		Dentist.bRightPlayerEscapedChair = false;
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION()
	private void OnMioWiggleCompleted()
	{	
		ADentistBossTool Tool;
		Tool = Dentist.Tools[EDentistBossTool::MioChair];
		if(Params.bDeactivateChairOnCompleted)
		{
			ADentistBossToolChair Chair = Cast<ADentistBossToolChair>(Tool);
			FDentistBossEffectHandlerOnChairDestroyedByEscapingParams EffectParams;
			EffectParams.Chair = Chair;
			UDentistBossEffectHandler::Trigger_OnChairDestroyedByEscaping(Dentist, EffectParams);
			Tool.Deactivate();
		}

		ActivatedPlayers.RemoveSingleSwap(Game::Mio);

		ADentistBossToolChair Chair = Cast<ADentistBossToolChair>(Tool);
		Chair.RestrainedPlayer.Reset();
		
		for(auto Player : ActivatedPlayers)
		{
			if(Settings.bChairStickWiggleEscape)
				Player.StopStickWiggle(Dentist);
			else
				Player.StopButtonMash(Dentist);
		}
	}

	UFUNCTION()
	private void OnZoeWiggleCompleted()
	{
		ADentistBossTool Tool;
		Tool = Dentist.Tools[EDentistBossTool::ZoeChair];
		if(Params.bDeactivateChairOnCompleted)
		{
			ADentistBossToolChair Chair = Cast<ADentistBossToolChair>(Tool);
			FDentistBossEffectHandlerOnChairDestroyedByEscapingParams EffectParams;
			EffectParams.Chair = Chair;
			UDentistBossEffectHandler::Trigger_OnChairDestroyedByEscaping(Dentist, EffectParams);
			Tool.Deactivate();
		}

		ActivatedPlayers.RemoveSingleSwap(Game::Zoe);

		ADentistBossToolChair Chair = Cast<ADentistBossToolChair>(Tool);
		Chair.RestrainedPlayer.Reset();

		for(auto Player : ActivatedPlayers)
		{
			if(Settings.bChairStickWiggleEscape)
				Player.StopStickWiggle(Dentist);
			else
				Player.StopButtonMash(Dentist);
		}
	}
};