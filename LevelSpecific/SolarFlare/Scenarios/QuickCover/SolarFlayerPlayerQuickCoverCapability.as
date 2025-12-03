class USolarFlayerPlayerQuickCoverCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"QuickCoverButtonMash");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	USolarFlarePlayerQuickCoverComponent UserComp;
	UButtonMashComponent MashComp;
	ASolarFlareVOManager VOManager;
	ASolarFlareSun Sun;

	float TotalDist;
	float Multiplier;
	FHazeAcceleratedFloat AccelFloat;

	float Progress;
	float ProgressPerPress = 0.09;
	float AutomaticMashRate = 12.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{	
		UserComp = USolarFlarePlayerQuickCoverComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (VOManager == nullptr)
			VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();

		if (Sun == nullptr)
		{
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
			TotalDist = (Sun.ActorLocation - Owner.ActorLocation).Size();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bQuickCoverActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bQuickCoverActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FButtonMashSettings Settings;
		Settings.ButtonAction = ActionNames::Interaction;
		Settings.Difficulty = EButtonMashDifficulty::Medium;
		Settings.Mode = EButtonMashMode::ButtonMash;
		Settings.WidgetPositionOffset = FVector(0,0,180.0);
		if (Player.IsMio())
			Settings.WidgetPositionOffset += FVector(0,35,0);
		else
			Settings.WidgetPositionOffset += FVector(0,-35,0);
		// Settings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
		Settings.ProgressionMode = EButtonMashProgressionMode::MashToProceedOnly;
		Settings.WidgetAttachComponent = Player.RootComponent; // ATTACH TO COMP IN ACTOR INSTEAD AND PLACE ABOVE PLAYERS HEADS!!!!!!!!!
		Player.StartButtonMash(Settings, this);
		Player.SetButtonMashAllowCompletion(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopButtonMash(this);
		AccelFloat.SnapTo(0);
		Progress = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Sun.CurrentFireDonut == nullptr || Sun.CurrentFireDonut.IsActorBeingDestroyed())
		{
			//Default 0.5
			Player.SetButtonMashGainMultiplier(this, 0.35);
			Multiplier = 0.5;
		}
		else
		{
			//Goes from 0.5 -> 1.5 based on distance
			//Subtract remaining distance by Ping multiplied by the current speed of the wave 
			float Alpha = Sun.CurrentFireDonut.GetRemainingDistanceToActor(Owner) / TotalDist;
			Alpha = 1.0 - Alpha;
			Alpha = Math::Clamp(Alpha, 0.0, 1.0);
			Multiplier = UserComp.FlareDistanceCurve.GetFloatValue(Alpha);
			PrintToScreen(f"{Multiplier}");

			Player.SetButtonMashGainMultiplier(this, Alpha);
		}

		if (HasControl())
		{
			if (ButtonMash::ShouldButtonMashesBeAutomatic(Player))
			{
				Progress += (ProgressPerPress * Multiplier) * AutomaticMashRate * DeltaTime;
				Progress = Math::Clamp(Progress, 0, 1);

				FSolarFlareQuickCoverButtonMashParams Params;
				Params.Player = Player;

				if (Player.IsMio())
					Params.Progress = UserComp.QuickCover.SyncFloatProgressMio.Value;
				else	
					Params.Progress = UserComp.QuickCover.SyncFloatProgressZoe.Value;

				USolarFlareQuickCoverEffectHandler::Trigger_QuickCoverButtonMashing(UserComp.QuickCover, Params);
				VOManager.TriggerQuickCoverButtonMashing(Player);				
			}
			else if (ButtonMash::ShouldButtonMashesBeHolds(Player))
			{
				if (IsActioning(ActionNames::Interaction))
				{
					Progress += (ProgressPerPress * Multiplier) * AutomaticMashRate * DeltaTime;
					Progress = Math::Clamp(Progress, 0, 1);

					FSolarFlareQuickCoverButtonMashParams Params;
					Params.Player = Player;

					if (Player.IsMio())
						Params.Progress = UserComp.QuickCover.SyncFloatProgressMio.Value;
					else	
						Params.Progress = UserComp.QuickCover.SyncFloatProgressZoe.Value;

					USolarFlareQuickCoverEffectHandler::Trigger_QuickCoverButtonMashing(UserComp.QuickCover, Params);
					VOManager.TriggerQuickCoverButtonMashing(Player);
				}
			}
			else
			{
				if (WasActionStarted(ActionNames::Interaction))
				{
					Progress += (ProgressPerPress * Multiplier);
					Progress = Math::Clamp(Progress, 0, 1);

					FSolarFlareQuickCoverButtonMashParams Params;
					Params.Player = Player;

					if (Player.IsMio())
						Params.Progress = UserComp.QuickCover.SyncFloatProgressMio.Value;
					else	
						Params.Progress = UserComp.QuickCover.SyncFloatProgressZoe.Value;

					USolarFlareQuickCoverEffectHandler::Trigger_QuickCoverButtonMashing(UserComp.QuickCover, Params);
					VOManager.TriggerQuickCoverButtonMashing(Player);
				}
			}

			AccelFloat.AccelerateTo(Progress, 0.3, DeltaTime);
			UserComp.QuickCover.UpdateProgress(UserComp.InteractionSide, Player, AccelFloat.Value / 2); 
		}
	}
};