
enum ERespawnState
{
	None,
	FadingOutBeforeRespawn,
	BlackScreen,
	FadingInAfterRespawn,
}

class UPlayerRespawnCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"PlayerHealth";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerHealthSettings HealthSettings;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	UFadeManagerComponent FadeComp;
	UPostProcessingComponent PostProcessComp;

	FRespawnLocation CurrentRespawn;
	ERespawnState State = ERespawnState::None;
	float StateActivatedTime = 0.0;

	bool bPlayerLocked = false;
	bool bHasFade = false;
	bool bRespawnTriggered = false;
	bool bHasRevived = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		FadeComp = UFadeManagerComponent::GetOrCreate(Owner);
		PostProcessComp = UPostProcessingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRespawnLocation& OutLocation) const
	{
		if (!HealthComp.bIsDead)
			return false;
		if (!HealthComp.bHasFinishedDying)
			return false;
		if (HealthComp.bIsGameOver)
			return false;
		if (HealthSettings.bEnableRespawnTimer && HealthComp.RespawnTimer < HealthSettings.RespawnTimer)
			return false;

		// NB: This isn't tagged on the capability itself, because we want blocking Respawn
		// to prevent _starting_ a respawn, but not interrupt any respawn that is already in progress.
		if (Player.IsCapabilityTagBlocked(n"Respawn"))
 			return false;

		if (RespawnComp.PrepareRespawnLocation(OutLocation))
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (State == ERespawnState::None)
			return true;
		if (HealthComp.bIsDead && bHasRevived)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bShowOverlay = false;

		// Show respawn overlay when mashing
		if (RespawnComp.bIsRespawnMashActive)
			bShowOverlay = true;

		// Show respawn overlay when we're dead and waiting for a respawn that is blocked
		if (HealthComp.bIsDead	
			&& HealthComp.bHasFinishedDying
			&& !HealthComp.bIsGameOver
			&& !Player.IsCapabilityTagBlocked(n"RespawnWaitingOverlay")
		)
		{
			bShowOverlay = true;
		}

		if (bShowOverlay)
		{
			if (RespawnComp.OverlayWidget == nullptr)
			{
				RespawnComp.OverlayWidget = Cast<UPlayerRespawnMashOverlayWidget>(
					Widget::AddFullscreenWidget(HealthComp.RespawnMashOverlayWidget, EHazeWidgetLayer::Gameplay, Player)
				);
				RespawnComp.OverlayWidget.SetWidgetZOrderInLayer(-1);
				RespawnComp.OverlayWidget.Initialize();
			}

			if ((HealthComp.RespawnTimer >= HealthSettings.RespawnTimer || !HealthSettings.bEnableRespawnTimer) && !RespawnComp.bIsRespawning)
				RespawnComp.OverlayWidget.bIsWaitingForRespawn = true;
			else
				RespawnComp.OverlayWidget.bIsWaitingForRespawn = false;
			RespawnComp.OverlayWidget.bShowAtTopOfScreenInFullscreen = HealthSettings.bShowRespawnTimerAtTheTopInFullscreen;
			RespawnComp.OverlayWidget.bIsBossHealthBarActive = HealthComp.IsBossHealthBarVisible.Get();
			RespawnComp.OverlayWidget.bIsRespawning = RespawnComp.bIsRespawning;
		}
		else
		{
			if (RespawnComp.OverlayWidget != nullptr)
			{
				RespawnComp.OverlayWidget.bIsWaitingForRespawn = false;
				Widget::RemoveFullscreenWidget(RespawnComp.OverlayWidget);
				RespawnComp.OverlayWidget = nullptr;
			}
		}
	}

	bool ShouldAffectCamera() const
	{
		if (SceneView::IsFullScreen())
		{
			if (!HealthSettings.bFadeOutEvenInFullscreen)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FRespawnLocation Location)
	{
		RespawnComp.bIsRespawning = true;
		HealthComp.bIsRespawning = true;
		CurrentRespawn = Location;
		bRespawnTriggered = false;
		bHasRevived = false;

		if (RespawnComp.OverlayWidget != nullptr)
		{
			RespawnComp.OverlayWidget.bIsWaitingForRespawn = false;
			RespawnComp.OverlayWidget.TriggeredRespawn();
		}

		//Reset all animations / data
		Player.Mesh.ResetAllAnimation();

		UDeathEffect::Trigger_RespawnStarted(Player);

		FRespawnLocationEventData DataToSend;
		DataToSend.RespawnTransform = Location.RespawnTransform;
		DataToSend.RespawnRelativeTo = Location.RespawnRelativeTo;
		DataToSend.RespawnPoint = Location.RespawnPoint;

		URespawnEffectHandler::Trigger_RespawnStarted(Player, DataToSend);
		Player.ClearViewSizeOverride(HealthComp, EHazeViewPointBlendSpeed::AcceleratedFast);

		StartFadeOut();
		LockPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UnlockPlayer();
		Player.ClearFade(this, 0.0);

		URespawnEffectHandler::Trigger_RespawnFinished(Player);
		RespawnComp.bIsRespawning = false;
		HealthComp.bIsRespawning = false;
	}

	void StartFadeOut()
	{
		State = ERespawnState::FadingOutBeforeRespawn;
		StateActivatedTime = Time::GameTimeSeconds;

		if (ShouldAffectCamera())
		{
			Player.ClearFade(this, 0.0);
			if (HealthSettings.RespawnFadeOutDuration != 0.0)
				Player.FadeOut(this, -1.0, HealthSettings.RespawnFadeOutDuration, HealthSettings.RespawnFadeInDuration);
			bHasFade = true;
		}
	}

	void StartBlackScreen()
	{
		State = ERespawnState::BlackScreen;
		StateActivatedTime = Time::GameTimeSeconds;

		FRespawnLocationEventData DataToSend;
		DataToSend.RespawnTransform = CurrentRespawn.RespawnTransform;
		DataToSend.RespawnRelativeTo = CurrentRespawn.RespawnRelativeTo;
		DataToSend.RespawnPoint = CurrentRespawn.RespawnPoint;
		URespawnEffectHandler::Trigger_RespawnFadedOut(Player, DataToSend);

		if (ShouldAffectCamera())
		{
			Player.ClearFade(this, 0.0);
			if (HealthSettings.RespawnBlackScreenDuration != 0.0)
				Player.FadeOut(this, -1.0, 0.0, HealthSettings.RespawnFadeInDuration);
			bHasFade = true;
		}
	}

	void StartFadeIn()
	{
		State = ERespawnState::FadingInAfterRespawn;
		StateActivatedTime = Time::GameTimeSeconds;

		if (ShouldAffectCamera())
		{
			Player.ClearFade(this, 0.0);
			if (HealthSettings.RespawnBlackScreenDuration != 0.0)
				Player.FadeOut(this, 0.0, 0.0, HealthSettings.RespawnFadeInDuration);
			bHasFade = true;
		}
	}

	void LockPlayer()
	{
		if (bPlayerLocked)
			return;
		bPlayerLocked = true;
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"GameplayAction", this);
	}

	void UnlockPlayer()
	{
		if (!bPlayerLocked)
			return;
		bPlayerLocked = false;
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"GameplayAction", this);
	}


	UFUNCTION(CrumbFunction)
	void CrumbTriggerRespawn(FRespawnLocation RespawnLocation, bool bTeleport, bool bIncludeCameraInTeleport)
	{
		bRespawnTriggered = true;
		CurrentRespawn = RespawnLocation;
		TriggerRespawn(bTeleport, bIncludeCameraInTeleport);
		UnlockPlayer();
	}

	void TriggerRespawn(bool bTeleport, bool bIncludeCameraInTeleport)
	{
		bHasRevived = true;
		if (HealthComp.bIsDead)
			HealthComp.Revive(true);

		if (bTeleport)
		{
			FMoveToDestination Destination(CurrentRespawn.RespawnRelativeTo, CurrentRespawn.RespawnTransform);
			FTransform Transform = Destination.CalculateDestination(Player.ActorTransform, FMoveToParams());

			Player.TeleportActor(Transform.Location, Transform.Rotator(), this, bIncludeCameraInTeleport);
			Player.SetActorVelocity(CurrentRespawn.RespawnWithVelocity);

			if (bIncludeCameraInTeleport && CurrentRespawn.bOffsetSpawnCameraRotation)
				Player.SnapCameraAtEndOfFrame((Transform.Rotation * FQuat(CurrentRespawn.CameraRotationOffset)).Rotator(), EHazeCameraSnapType::World);
				
			FVector RelativeBasePosition;
			if (CurrentRespawn.RespawnRelativeTo != nullptr)
				RelativeBasePosition = CurrentRespawn.RespawnRelativeTo.WorldLocation;

			TEMPORAL_LOG(Player, "Health")
				.Event(f"Respawned at {CurrentRespawn.RespawnPoint}, location {Transform.Location}, relative to {CurrentRespawn.RespawnRelativeTo}, with transform {RelativeBasePosition} and relative {CurrentRespawn.RespawnTransform}");
		}

		UDeathEffect::Trigger_RespawnTriggered(Player);
		UDeathEffect::Trigger_DeathAndRespawnCycleCompleted(Player);

		URespawnEffectHandler::Trigger_RespawnTriggered(Player);
		RespawnComp.OnPlayerRespawned.Broadcast(Player);
		PostProcessComp.SetVignetteOpacity(1.0, 0.0);

		if (CurrentRespawn.RespawnPoint != nullptr)
			CurrentRespawn.RespawnPoint.OnRespawnTriggered(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HealthComp.bIsDead)
		{
			// Something else made us alive. Deal with it
			if (State != ERespawnState::FadingInAfterRespawn)
			{
				UnlockPlayer();
				StartFadeIn();
			}
		}

		if (bHasFade && !ShouldAffectCamera())
		{
			// We had a fade but went fullscreen, nuke the fade
			Player.ClearFade(this, 0.0);
			PostProcessComp.SetVignetteOpacity(1.0, 0.0);
			bHasFade = false;
		}

		float TimeInState = Time::GetGameTimeSince(StateActivatedTime);
		if (State == ERespawnState::FadingOutBeforeRespawn)
		{
			if (ShouldAffectCamera() && HealthSettings.RespawnBlackScreenDuration != 0.0)
			{
				float VignetteIntensity = Math::Saturate(TimeInState / Math::Max(HealthSettings.RespawnFadeOutDuration, 0.1));
				PostProcessComp.SetVignetteOpacity(1.0 + VignetteIntensity * 3.0, 0.0);
			}
			else
			{
				PostProcessComp.SetVignetteOpacity(1.0, 0.0);
			}

			if ((TimeInState > HealthSettings.RespawnFadeOutDuration && !HealthComp.bIsGameOver) || bRespawnTriggered)
			{
				// Go to black screen after fade out is done
				StartBlackScreen();
			}
		}
		else if (State == ERespawnState::BlackScreen)
		{
			if (Player.HasControl())
			{
				if ((TimeInState > HealthSettings.RespawnBlackScreenDuration && !HealthComp.bIsGameOver) || bRespawnTriggered)
				{
					// Actually trigger the respawn at the end of the black screen
					if (CurrentRespawn.bRecalculateOnRespawnTriggered)
						RespawnComp.PrepareRespawnLocation(CurrentRespawn);

					bool bTeleportPlayer = !Player.bIsControlledByCutscene;

					// If the players are in fullscreen, we never wan't to snap the camera
					// since that would snap it for the player that is not respawning
					bool bIncludeCameraInTeleport = ShouldAffectCamera();

					CrumbTriggerRespawn(CurrentRespawn, bTeleportPlayer, bIncludeCameraInTeleport);
					StartFadeIn();
				}
			}
			else
			{
				// On the remote side, start fading in whenever the control side has triggered the respawn
				if (bRespawnTriggered)
				{
					StartFadeIn();
				}
			}

		}
		else if (State == ERespawnState::FadingInAfterRespawn)
		{
			PostProcessComp.SetVignetteOpacity(1.0, 0.0);

			if (TimeInState > HealthSettings.RespawnFadeInDuration)
			{
				// Stop the respawn capability now that we're done
				State = ERespawnState::None;

				Player.ClearFade(this, 0.0);
				bHasFade = false;
			}
		}
	}
};