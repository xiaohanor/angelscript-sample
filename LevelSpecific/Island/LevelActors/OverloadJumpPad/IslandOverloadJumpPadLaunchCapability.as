struct FIslandOverloadJumpPadLaunchActivatedParams
{
	bool bForceLaunch = false;
}

class UIslandOverloadJumpPadLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandOverloadJumpPad JumpPad;

	TArray<AHazePlayerCharacter> PlayersWithOverridenSettings;

	TPerPlayer<UIslandOverloadJumpPadPlayerComponent> PlayerComps;

	TPerPlayer<UPlayerMovementComponent> MoveComp;

	bool bFirstPanelHasResetSinceLaunch = false;
	bool bSecondPanelHasResetSinceLaunch = false;
	bool bPanelListenerIsCompleted = false;

	FVector PlatformLaunchStartLocation;
	FVector PlatformLaunchTarget;

	bool bPlatformHasBeenExtended = false;

	const float PlatformRetractInterpSpeed = 50.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpPad = Cast<AIslandOverloadJumpPad>(Owner);

		devCheck(JumpPad.Panel != nullptr, f"{this} does not have a reference to an overload panel");

		if(JumpPad.Panel == nullptr)
			return;

		if(JumpPad.PanelListener != nullptr)
		{
			JumpPad.PanelListener.OnCompleted.AddUFunction(this, n"OnListenerCompleted");
		}

		JumpPad.Panel.OnOvercharged.AddUFunction(this, n"OnFirstPanelOvercharged");
		JumpPad.Panel.OnReset.AddUFunction(this, n"OnFirstPanelReset");

		if(JumpPad.bRequireSecondPanel)
		{
			devCheck(JumpPad.SecondPanel != nullptr, f"{this} does not have a reference to a second overload panel, but RequireSecondPanel is ticked");

			JumpPad.SecondPanel.OnOvercharged.AddUFunction(this, n"OnSecondPanelOvercharged");
			JumpPad.SecondPanel.OnReset.AddUFunction(this, n"OnSecondPanelReset");
		}

		PlatformLaunchTarget = JumpPad.PadMesh.RelativeLocation;

		for(auto Player : Game::Players)
		{
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
			PlayerComps[Player] = UIslandOverloadJumpPadPlayerComponent::GetOrCreate(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverloadJumpPadLaunchActivatedParams& Params) const
	{
		// if(JumpPad.PanelListener != nullptr)
		// {
		// 	if(bPanelListenerIsCompleted)
		// 		return true;

		// 	return false;
		// }

		if(JumpPad.Panel == nullptr)
			return false;

		if(JumpPad.bRequireSecondPanel)
		{
			if(Network::IsGameNetworked())
			{
				if(JumpPad.bHandshakeSuccessful)
				{
					Params.bForceLaunch = true;
					return true;
				}

				return false;
			}

			if(JumpPad.PlayersInsideBox.Num() == 0)
				return false;

			if(JumpPad.OtherJumpPad.PlayersInsideBox.Num() == 0)
				return false;

			if(JumpPad.bFirstPanelIsOvercharged
			&& JumpPad.bSecondPanelIsOverCharged)
				return true;
		}
		else
		{
			if(JumpPad.bFirstPanelIsOvercharged)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(JumpPad.Panel == nullptr)
			return true;

		if(bPlatformHasBeenExtended)
		{
			if(JumpPad.Panel.bResetChargeOnOvercharge)
				return true;

			if(JumpPad.bRequireSecondPanel)
			{
				if(bFirstPanelHasResetSinceLaunch 
				&& bSecondPanelHasResetSinceLaunch)
					return true;
			}
			else
			{
				if(bFirstPanelHasResetSinceLaunch)
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverloadJumpPadLaunchActivatedParams Params)
	{
		JumpPad.bHandshakeSuccessful = false;
		if(JumpPad.bRequireSecondPanel)
		{
			JumpPad.Panel.SetCompleted();
			JumpPad.SecondPanel.SetCompleted();
		}

		JumpPad.bFirstPanelIsOvercharged = false;
		bPanelListenerIsCompleted = true;
		LaunchPlayersInsideBox(Params.bForceLaunch);

		PlatformLaunchStartLocation = JumpPad.PadMesh.RelativeLocation;

		JumpPad.bIsLaunching = true;
		JumpPad.CurrentState = EIslandOverloadJumpPadMovementState::Launching;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bPlatformHasBeenExtended = false;

		JumpPad.bIsLaunching = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		for(int i = PlayersWithOverridenSettings.Num() ; i > 0 ; i--)
		{
			auto Player = PlayersWithOverridenSettings[i - 1];
			if(MoveComp[Player].IsOnAnyGround())
			{
				Player.ClearSettingsByInstigator(this);
				Player.UnblockCapabilities(CapabilityTags::StickInput, this);
				Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
				Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
				Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);
				Player.UnblockCapabilities(PlayerMovementTags::WallScramble, this);
				Player.ClearPointOfInterestByInstigator(this);
				PlayersWithOverridenSettings.RemoveAt(i - 1);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bPlatformHasBeenExtended)
		{
			const float LaunchAlpha = Math::Clamp(ActiveDuration / JumpPad.LaunchDuration, 0.0, 1.0); 
			JumpPad.PadMesh.RelativeLocation = Math::Lerp(PlatformLaunchStartLocation, PlatformLaunchTarget, LaunchAlpha);
			
			if(ActiveDuration >= JumpPad.LaunchDuration)
				bPlatformHasBeenExtended = true;
		}
	}

	UFUNCTION()
	private void OnListenerCompleted()
	{
		bPanelListenerIsCompleted = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFirstPanelOvercharged()
	{
		JumpPad.bFirstPanelIsOvercharged = true;

		AHazePlayerCharacter PlayerToBlockPanelFor = JumpPad.Panel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
		JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, false, true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFirstPanelReset()
	{
		if(JumpPad.bRequireSecondPanel)
			JumpPad.bFirstPanelIsOvercharged = false;

		bFirstPanelHasResetSinceLaunch = true;
		
		// Only want to unblock if both panels have reset
		if(JumpPad.bRequireSecondPanel
		&& JumpPad.bIsLaunching)
		{
			if(bSecondPanelHasResetSinceLaunch)
			{
				AHazePlayerCharacter PlayerToBlockPanelFor = JumpPad.Panel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
				JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, true, true);

				PlayerToBlockPanelFor = JumpPad.SecondPanel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
				JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, true, false);
			}
		}
		else
		{
			AHazePlayerCharacter PlayerToBlockPanelFor = JumpPad.Panel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
			JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, true, true);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSecondPanelOvercharged()
	{
		JumpPad.bSecondPanelIsOverCharged = true;

		AHazePlayerCharacter PlayerToBlockPanelFor = JumpPad.SecondPanel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
		JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, false, false);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSecondPanelReset()
	{
		JumpPad.bSecondPanelIsOverCharged = false;
		bSecondPanelHasResetSinceLaunch = true;

		// Only want to unblock if both panels have reset
		if(JumpPad.bRequireSecondPanel
		&& JumpPad.bIsLaunching)
		{
			if(bFirstPanelHasResetSinceLaunch)
			{
				AHazePlayerCharacter PlayerToBlockPanelFor = JumpPad.Panel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
				JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, true, true);

				PlayerToBlockPanelFor = JumpPad.SecondPanel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
				JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, true, false);
			}
		}
		else
		{
			AHazePlayerCharacter PlayerToBlockPanelFor = JumpPad.SecondPanel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
			JumpPad.TogglePanelForPlayer(PlayerToBlockPanelFor, true, false);
		}
	}

	private void LaunchPlayersInsideBox(bool bForceLaunch)
	{
		AHazePlayerCharacter PlayerAdded = nullptr;
		if(bForceLaunch)
		{
			TArray<AHazePlayerCharacter> PlayersToLaunch = Game::GetPlayersSelectedBy(JumpPad.UsableByPlayer);
			AHazePlayerCharacter PlayerToLaunch = PlayersToLaunch[0];
			bool bAdded = JumpPad.PlayersInsideBox.AddUnique(PlayerToLaunch);
			if(bAdded)
			{
				PlayerAdded = PlayerToLaunch;
			}
		}

		for(auto Player : JumpPad.PlayersInsideBox)
		{
			auto GravitySettings = UMovementGravitySettings::GetSettings(Player);

			Player.SetActorVelocity(FVector::ZeroVector);

			Player.ApplySettings(IslandJumpPadPlayerAirSettings, this, EHazeSettingsPriority::Override);
			Player.BlockCapabilitiesExcluding(CapabilityTags::StickInput, CameraTags::CameraControl, this);
			Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
			Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
			Player.BlockCapabilities(PlayerMovementTags::WallRun, this);
			Player.BlockCapabilities(PlayerMovementTags::WallScramble, this);

			FHazePointOfInterestFocusTargetInfo FocusTarget;
			FVector Pos = Player.ActorLocation + (JumpPad.LandLocation.WorldLocation - Player.ActorLocation).GetSafeNormal2D() * 10000.0;
			FocusTarget.SetFocusToWorldLocation(Pos);

			FApplyPointOfInterestSettings POISettings;

			FPointOfInterestInputSuspensionSettings SuspensionSettings;
			SuspensionSettings.DelayBeforeResume = JumpPad.DelayBeforeResumePOI;
			Player.ApplyPointOfInterestSuspendOnInput(this, FocusTarget, POISettings, SuspensionSettings, 2.0);
			Player.SetMovementFacingDirection(FQuat::MakeFromZX(FVector::UpVector, JumpPad.LandLocation.WorldLocation - Player.ActorLocation));

			PlayersWithOverridenSettings.Add(Player);

			FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, JumpPad.LandLocation.WorldLocation, GravitySettings.GravityAmount, JumpPad.HeightToReach, GravitySettings.TerminalVelocity);
			Player.AddMovementImpulse(Impulse);
			Player.FlagForLaunchAnimations(Impulse);

			Player.PlayCameraShake(JumpPad.LaunchCameraShake, this);
			Player.PlayForceFeedback(JumpPad.LaunchFF,	 false, false, this);

			PlayerComps[Player].LastLaunchedTime = Time::GameTimeSeconds;
		}

		if(PlayerAdded != nullptr)
			JumpPad.PlayersInsideBox.RemoveSingleSwap(PlayerAdded);

		UIslandOverloadJumpPadEventHandler::Trigger_Launched(JumpPad);

		bFirstPanelHasResetSinceLaunch = false;
		bSecondPanelHasResetSinceLaunch = false;
	}
}