event void FOnGlitchActive();
event void FOnPickupCompleted();

class AMeltdownGlitchShootingPickup : ADoubleInteractionActor
{
	bool bStartedButtonMash = false;
	bool bPickedUp = false;

	default bBlockTickOnDisable = false;

	 UPROPERTY(DefaultComponent)
	 UHazeCameraComponent MioCamera;
	 UPROPERTY(DefaultComponent)
	 UHazeCameraComponent ZoeCamera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent FullscreenCamera;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams ZoeEnter;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams MioEnter;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams MioStruggle;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams MioMh;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams ZoeStruggle;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams ZoeMh;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftInteractWidget;

	UPROPERTY(DefaultComponent)
	USceneComponent RightInteractWidget;

	UPROPERTY(EditAnywhere)
	bool bAffectCamera = true;

	UPROPERTY(EditAnywhere)
	bool bRequiresButtonMash = true;

	UPROPERTY(EditAnywhere)
	bool bApplyProjectionOffset = true;

	UPROPERTY()
	TPerPlayer<UAnimSequence> MHAnimation;
	UPROPERTY()
	TPerPlayer<UAnimSequence> StruggleAnimation;

	UPROPERTY(EditAnywhere)
	FTimeDilationEffect WorldTimeDilation;

	UPROPERTY(EditAnywhere)
	FTimeDilationEffect PlayerTimeDilation;

	UPROPERTY()
	FOnGlitchActive GlitchActive;

	UPROPERTY()
	FOnPickupCompleted PickupCompleted;

	UPROPERTY(EditAnywhere)
	TArray<AMeltdownGlitchShootingPowerup> Powerups;

	UPROPERTY(EditAnywhere)
	int RequiredPowerupsForActivation = -1;

	UPROPERTY(EditAnywhere)
	float TimeBetweenPowerups = 3;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool bImpossible = false;

	int PowerupsActivated = 0;
	bool bBroadcastedFinish = false;
	bool bAllCollected = false;
	bool bHasCompletedButtonMash = false;
	const FName ButtonMashInstigatorTag = n"MeltdownGlitchShootingPickup";
	float RealTimeInteractStarted;
	TPerPlayer<bool> bIsMashing;
	TPerPlayer<bool> PlayerIsInvulnerable;
	TPerPlayer<float> PlayerInvulnerabilityTimers;
	TPerPlayer<float> PlayerInteractTime;
	TPerPlayer<bool> PlayerIsInteracting;
	bool bAppliedFullscreen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnDoubleInteractionLockedIn.AddUFunction(this, n"OnLockInPickupDoubleInteract");
		LeftInteraction.OnInteractionStopped.AddUFunction(this, n"ExitedInteraction");
		RightInteraction.OnInteractionStopped.AddUFunction(this, n"ExitedInteraction");

		OnEnterBlendedIn.AddUFunction(this, n"OnEntered");
		OnCancelBlendingOut.AddUFunction(this, n"OnCanceled");

		AddActorDisable(this);
		PreventDoubleInteractionCompletion(this);
	}

	UFUNCTION()
	private void ExitedInteraction(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		ClearFromPlayer(Player);
		if (!bStartedButtonMash)
			RemoveInvulnerability(Player);
		PlayerIsInteracting[Player] = false;
	}

	UFUNCTION()
	private void OnCanceled(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                        UInteractionComponent InteractionComponent)
	{
		ClearFromPlayer(Player);
		LingerInvulnerability(Player, 0.5);
		PlayerIsInteracting[Player] = false;
	}

	UFUNCTION()
	private void OnEntered(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                       UInteractionComponent InteractionComponent)
	{
		PlayerIsInteracting[Player] = true;
		PlayerInteractTime[Player] = Time::RealTimeSeconds;
		AddInvulnerability(Player);
		ApplyToPlayer(Player);
	}

	void ApplyToPlayer(AHazePlayerCharacter Player)
	{
		if (bAffectCamera)
		{
		//	UHazeCameraComponent Camera = Player.IsMio() ? MioCamera : ZoeCamera;
			UHazeCameraComponent Camera = FullscreenCamera;
			Player.ActivateCamera(Camera, 4.0, this);
		}

		auto HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.DamageTakenMultiplier.Apply(0.5, this);
		HealthComp.OnPlayerTookDamage.AddUFunction(this, n"OnPlayerTookDamage");

		if (bApplyProjectionOffset && bAffectCamera)
		{
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			if (Player.IsMio())
				ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(-1, 0), this, BlendTime = 2.0);
			else
				ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(1, 0), this, BlendTime = 2.0);
		}
	}

	UFUNCTION()
	private void OnPlayerTookDamage(AHazePlayerCharacter Player, float DamageAmount)
	{
		// If both players are inside the interaction we can no longer be booted out
		if (bStartedButtonMash)
			return;

		if (Player.HasControl())
		{
			if (LeftInteraction.IsInteracting(Player) || RightInteraction.IsInteracting(Player))
			{
				// Only boot players out through damage if they've been in for a while
				if (Time::GetRealTimeSince(PlayerInteractTime[Player]) > 5.0)
				{
					if (LeftInteraction.CanPlayerCancel(Player))
						LeftInteraction.KickPlayerOutOfInteraction(Player);
					if (RightInteraction.CanPlayerCancel(Player))
						RightInteraction.KickPlayerOutOfInteraction(Player);
				}
			}
		}
	}

	void ClearFromPlayer(AHazePlayerCharacter Player, bool bSnapOffset = false)
	{
		Player.DeactivateCameraByInstigator(this, 4.0);

		auto HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.DamageTakenMultiplier.Clear(this);
		HealthComp.OnPlayerTookDamage.UnbindObject(this);

		if (bApplyProjectionOffset)
		{
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			if (bSnapOffset)
				ViewPoint.ClearOffCenterProjectionOffset(this, 0.0);
			else
				ViewPoint.ClearOffCenterProjectionOffset(this, BlendTime = 0.0);
		}
	}

	void AddInvulnerability(AHazePlayerCharacter Player)
	{
		if (!PlayerIsInvulnerable[Player])
		{
			// Player.AddDamageInvulnerability(this);
			Player.BlockCapabilities(n"Death", this);

			PlayerIsInvulnerable[Player] = true;
			PlayerInvulnerabilityTimers[Player] = -1.0;
		}
	}

	void LingerInvulnerability(AHazePlayerCharacter Player, float Duration)
	{
		AddInvulnerability(Player);
		PlayerInvulnerabilityTimers[Player] = Math::Max(PlayerInvulnerabilityTimers[Player], Duration);
	}

	void RemoveInvulnerability(AHazePlayerCharacter Player)
	{
		if (PlayerIsInvulnerable[Player])
		{
			// Player.RemoveDamageInvulnerability(this);
			Player.UnblockCapabilities(n"Death", this);

			PlayerIsInvulnerable[Player] = false;
			PlayerInvulnerabilityTimers[Player] = -1.0;
		}
	}

	UFUNCTION(BlueprintCallable)
	void GlitchSpawnVFX()
	{
		UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnGlitchActive(this);
	}

	UFUNCTION()
	private void OnLockInPickupDoubleInteract()
	{
		if(bAffectCamera)
		{
			bStartedButtonMash = true;
			RealTimeInteractStarted = Time::RealTimeSeconds;
		}

		UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPickupStarted(this);

		if(bAffectCamera)
		{
			for (auto Player : Game::Players)
			{
				FButtonMashSettings MashSettings;
				MashSettings.Duration = 2;
				MashSettings.bSyncWithNetworkLatestData = true;

				 if(Player.IsMio())
				MashSettings.WidgetAttachComponent = RightInteractWidget;
				
				 if(Player.IsZoe())
				 MashSettings.WidgetAttachComponent = LeftInteractWidget;

				Player.StartActorTimeDilationEffect(PlayerTimeDilation,this);
				TimeDilation::StartWorldTimeDilationEffect(WorldTimeDilation,this);

				if (bImpossible)
				{
					MashSettings.Duration = 3;
					MashSettings.Difficulty = EButtonMashDifficulty::Hard;
				}
				Player.StartButtonMash(MashSettings, ButtonMashInstigatorTag);
				Player.SetButtonMashAllowCompletion(ButtonMashInstigatorTag, false);

				AddInvulnerability(Player);

				if (!bImpossible)
				{
					auto GlitchComp = UMeltdownGlitchShootingUserComponent::Get(Player);
					GlitchComp.ActivateGlitchShooting();
				}
			}
		}

	}

	UFUNCTION(BlueprintEvent)
	void StartTimeDilation()
	{
		
	}

	int GetPowerupCountForTriggering() const
	{
		if (RequiredPowerupsForActivation > 0)
			return RequiredPowerupsForActivation;
		else
			return Powerups.Num();
	}

	UFUNCTION(DevFunction)
	void SpawnPowerups()
	{
		DisableDoubleInteraction(this);
		RemoveActorDisable(this);

		float Delay = 0.0;
		for (AMeltdownGlitchShootingPowerup Powerup : Powerups)
		{
			Powerup.Spawn(this, Delay);
			Delay += 1.0;
		}

		PowerupsActivated = 0;
		bBroadcastedFinish = false;
		bAllCollected = false;

		if (PowerupsActivated >= GetPowerupCountForTriggering())
			CollectedAllPowerups();

		UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPowerupsSpawned(this);
	}

	void CollectPowerup(AMeltdownGlitchShootingPowerup Powerup, AHazePlayerCharacter CollectedByPlayer)
	{
		UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPowerupCollected(this, FMeltdownGlitchShootingPickupPowerupParams(Powerup, CollectedByPlayer));

		if (!bAllCollected)
		{
			PowerupsActivated += 1;
			if (PowerupsActivated >= GetPowerupCountForTriggering())
				CollectedAllPowerups();
		}
	}

	UFUNCTION(DevFunction)
	void CollectedAllPowerups()
	{
		UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnAllPowerupsCollected(this);
		bAllCollected = true;

		PowerupsActivated = GetPowerupCountForTriggering();
		GlitchSpawnVFX();

		for (auto Powerup : Powerups)
		{
			if (!Powerup.bCollected)
				Powerup.DespawnFromActivation();
		}

		Timer::SetTimer(this, n"CreateGlitch", 3.0);
	}

	UFUNCTION(BlueprintEvent)
	void GlitchCutscene()
	{

	}

	UFUNCTION(BlueprintCallable)
	void InstantlyActivateGlitch()
	{
		RemoveActorDisable(this);
	//	EnableDoubleInteraction(this);
		UnhideGlitchCutscene();
	//	GlitchActive.Broadcast();
	}

	UFUNCTION()
	private void CreateGlitch()
	{
		UnhideGlitch();
		GlitchActive.Broadcast();

		for (AMeltdownGlitchShootingPowerup Powerup : Powerups)
			Powerup.GlitchCreated();

		if (bRequiresButtonMash)
		{
			EnableDoubleInteraction(this);
		}
		else
		{
			for (auto Player : Game::Players)
			{
				auto GlitchComp = UMeltdownGlitchShootingUserComponent::Get(Player);
				GlitchComp.ActivateGlitchShooting();
			}

			bPickedUp = true;
			bStartedButtonMash = true;
			Timer::SetTimer(this, n"DespawnPickup", 1.0);
			DeactivateVFX();
			Finished();

			UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPickupFinished(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void DeactivateVFX()
	{}



	UFUNCTION()
	private void DespawnPickup()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void UnhideGlitch()
	{

	}

	UFUNCTION(BlueprintEvent)
	void UnhideGlitchCutscene()
	{

	}

	UFUNCTION(BlueprintEvent)
	void Finished()
	{

	}

	UFUNCTION(NetFunction)
	private void NetTriggerPickup()
	{
		TriggerPickup();
	}

	UFUNCTION(DevFunction)
	private void TriggerPickup()
	{

		for (auto Player : Game::Players)
		{
			Player.StopButtonMash(ButtonMashInstigatorTag);
			ClearFromPlayer(Player, true);
			Player.StopActorTimeDilationEffect(this);

			AllowDoubleInteractionCompletion(this);
			LingerInvulnerability(Player, 2.5);
		}

		TimeDilation::StopWorldTimeDilationEffect(this);
		PickupCompleted.Broadcast();
		bPickedUp = true;
		bStartedButtonMash = true;


		if (!bImpossible)
		{

			Timer::SetTimer(this, n"DespawnPickup", 2.0);
			DeactivateVFX();
			Finished();

			UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPickupFinished(this);
		}		
	}

	UFUNCTION()
	void ResetGlitch()
	{
		PreventDoubleInteractionCompletion(this);
		bPickedUp = false;
		bStartedButtonMash = false;
		bHasCompletedButtonMash = false;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl() && !bPickedUp && bStartedButtonMash)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				float MashRate;
				bool bMashingSufficiently;
				Player.GetButtonMashCurrentRate(ButtonMashInstigatorTag, MashRate, bMashingSufficiently);

				if (bMashingSufficiently)
				{
					if (!bIsMashing[Player])
					{
						Player.PlaySlotAnimation(Animation = StruggleAnimation[Player], bLoop = true);
						bIsMashing[Player] = true;
					}
				}
				else
				{
					if (bIsMashing[Player])
					{
						Player.PlaySlotAnimation(Animation = MHAnimation[Player], bLoop = true);
						bIsMashing[Player] = false;
					}
				}
			}
			

			float CompleteThreshold = 0.95;
			 if (bImpossible)
			 	CompleteThreshold = 0.5;
			bool bCanComplete = Game::Mio.GetButtonMashProgress(ButtonMashInstigatorTag) >= CompleteThreshold && Game::Zoe.GetButtonMashProgress(ButtonMashInstigatorTag) >= CompleteThreshold;
			if (bCanComplete)
			{
				if (!bHasCompletedButtonMash)
				{
					bHasCompletedButtonMash = true;
					for (auto Player : Game::Players)
						Player.StopButtonMash(ButtonMashInstigatorTag);
				}
			}

			if (bHasCompletedButtonMash && (Time::GetRealTimeSince(RealTimeInteractStarted) >= 2.0 || !bAffectCamera))
			{
				NetTriggerPickup();
				for (auto Player : Game::Players)
					LingerInvulnerability(Player, 0.5);
			}
		}

		for (auto Player : Game::Players)
		{
			float Progress = Game::Mio.GetButtonMashProgress(ButtonMashInstigatorTag);

			auto UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
			if (UserComp.Weapon == nullptr)
				continue;

			USkeletalMeshComponent Mesh = USkeletalMeshComponent::Get(UserComp.Weapon);
			Mesh.SetScalarParameterValueOnMaterials(n"Opacity", Math::Saturate(Progress * 2.0));
			Mesh.SetScalarParameterValueOnMaterials(n"Display Frame", Progress);
		}

		for (auto Player : Game::Players)
		{
			if (PlayerIsInvulnerable[Player] && PlayerInvulnerabilityTimers[Player] >= 0.0)
			{
				PlayerInvulnerabilityTimers[Player] -= DeltaSeconds;
				if (PlayerInvulnerabilityTimers[Player] <= 0.0)
				{
					RemoveInvulnerability(Player);
				}
			}
		}

		if (bBroadcastedFinish == false && PowerupsActivated > 0)
		{
			bool bAllHaveReachedTarget = true;
			for(auto IterPowerUp : Powerups)
			{
				if(IterPowerUp.IsActorDisabled() == false)
				{
					bAllHaveReachedTarget = false;
					break;
				}
			}

			if(bAllHaveReachedTarget)
			{
				bBroadcastedFinish = true;
				UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnAllReachedTarget(this);
			}
		}

		// Snap to fullscreen once both players are interacting and blended
//		if (!bImpossible)
		{
			bool bBothPlayersFullyInteracting = true;
			for (auto Player : Game::Players)
			{
				if (!PlayerIsInteracting[Player])
				{
					bBothPlayersFullyInteracting = false;
					break;
				}

				auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
		//		Print("" + ViewPoint.BlendedOffCenterProjectionOffset.Value.X);
				if (Math::Abs(ViewPoint.BlendedOffCenterProjectionOffset.Value.X) < 0.9999 && !bAppliedFullscreen)
					bBothPlayersFullyInteracting = false;
				if (Time::GetRealTimeSince(PlayerInteractTime[Player]) < 3.5)
					bBothPlayersFullyInteracting = false;
			}

			if (bBothPlayersFullyInteracting)
			{
				if (!bAppliedFullscreen)
				{
					Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
					bAppliedFullscreen = true;

					for (auto Player : Game::Players)
					{
						auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
						ViewPoint.ClearOffCenterProjectionOffset(this, 0.0);
					}
				}
			}
			else
			{
				if (bAppliedFullscreen)
				{
					Game::Mio.ClearViewSizeOverride(this);
					bAppliedFullscreen = false;
					
					if (bAffectCamera && bApplyProjectionOffset)
					{
						for (auto Player : Game::Players)
						{
							if (!PlayerIsInteracting[Player])
								continue;

							auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
							if (Player.IsMio())
								ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(-1, 0), this, BlendTime = 2.0);
							else
								ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(1, 0), this, BlendTime = 2.0);
						}
					}
				}
			}
		}
	}
};

class AMeltdownGlitchShootingPowerup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UInteractionComponent CollectInteraction;
	default CollectInteraction.RelativeLocation = FVector(0, 0, -70);
	default CollectInteraction.bUseLazyTriggerShapes = true;
	default CollectInteraction.bIsImmediateTrigger = true;
	default CollectInteraction.MovementSettings = FMoveToParams::NoMovement();
	default CollectInteraction.FocusShape = FHazeShapeSettings::MakeSphere(3000.0);
	default CollectInteraction.ActionShape = FHazeShapeSettings::MakeSphere(300.0);

	FHazeAcceleratedVector AccLocation;
	FVector TargetLocation;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PickupShake;

	UPROPERTY()
	UForceFeedbackEffect PickupForceFeedback;

	AMeltdownGlitchShootingPickup GlitchPickup;
	FTransform SpawnTransform;

	bool bCollected = false;
	bool bPendingCollect = false;
	AHazePlayerCharacter PendingCollectPlayer;
	bool bHasTriggeredPreReached = false;
	bool bFinishedSpawning = false;
	bool bDespawned = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		CollectInteraction.OnInteractionStarted.AddUFunction(this, n"OnCollectPressed");
	}

	void Spawn(AMeltdownGlitchShootingPickup Pickup, float Delay)
	{
		GlitchPickup = Pickup;
		SpawnTransform = ActorRelativeTransform;

		Timer::SetTimer(this, n"OnSpawnAfterDelay", Delay+0.01);
	}

	UFUNCTION()
	private void OnSpawnAfterDelay()
	{
		if (bDespawned)
			return;
		RemoveActorDisable(this);
		UMeltdownGlitchShootingPowerupEffectHandler::Trigger_Spawn(this);
		bFinishedSpawning = true;
		bHasTriggeredPreReached = false;

		UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPowerupDelayedSpawned(GlitchPickup, FMeltdownGlitchShootingDelayedSpawnPowerupParams(this));

		if (bPendingCollect)
		{
			bPendingCollect = false;
			if (!bCollected)
				Collect(PendingCollectPlayer);
		}
	}

	void Collect(AHazePlayerCharacter CollectedByPlayer)
	{
		bCollected = true;

		TargetLocation = GlitchPickup.ActorLocation + FVector(0, 0, 150);
		AccLocation.SnapTo(ActorLocation, FVector(0, 0, 1500));

		FMeltdownGlitchShootingPowerupCollectParams Params;
		Params.TargetLocation = TargetLocation;

		UMeltdownGlitchShootingPowerupEffectHandler::Trigger_Collect(this, Params);
		GlitchPickup.CollectPowerup(this, CollectedByPlayer);
		Game::GetClosestPlayer(ActorLocation).PlayCameraShake(PickupShake, this);
		Game::GetClosestPlayer(ActorLocation).PlayForceFeedback(PickupForceFeedback, false, false,this);
		

		CollectInteraction.Disable(n"Collected");
	}

	void DespawnFromActivation()
	{
		check(!bCollected);
		Timer::SetTimer(this, n"FinishDespawning", 0.1);

		bDespawned = true;
		bFinishedSpawning = true;

		if (bPendingCollect)
		{
			bPendingCollect = false;
			if (!bCollected)
				Collect(PendingCollectPlayer);
		}
	}

	UFUNCTION()
	private void FinishDespawning()
	{
		AddActorDisable(this);
	}

	void GlitchCreated()
	{
		UMeltdownGlitchShootingPowerupEffectHandler::Trigger_GlitchCreated(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bCollected)
		{
			// Bob up and down a bit
			float BobAlpha = Math::Sin((Time::GameTimeSeconds + (Name.Hash % 100) * 0.3334) * 1.2);

			ActorRelativeLocation = SpawnTransform.Location + FVector(0, 0, BobAlpha * 20.0);
		}
		else
		{
			// Move to the glitch
			AccLocation.AccelerateTo(TargetLocation, 4.0, DeltaSeconds);
			ActorLocation = AccLocation.Value;

			if(!bHasTriggeredPreReached && AccLocation.Value.Distance(TargetLocation) < 500.0)
			{
				bHasTriggeredPreReached = true;
				UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPrePowerupReachedGlitch(GlitchPickup);

				if(GlitchPickup.bAllCollected)
					UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPreAllReachedTarget(GlitchPickup);				
			}

			if (AccLocation.Value.Distance(TargetLocation) < 50.0)
			{
				UMeltdownGlitchShootingPowerupEffectHandler::Trigger_ReachedGlitch(this);
				UMeltdownGlitchShootingPickupEffectHandler::Trigger_OnPowerupReachedGlitch(GlitchPickup);
				AddActorDisable(this);
			}
		}
	}

	UFUNCTION()
	private void OnCollectPressed(UInteractionComponent Interact, AHazePlayerCharacter Player)
	{
		// Already collected, could be both players collected it at the same time
		if (bCollected)
			return;

		CollectInteraction.Disable(n"Collected");

		if (bFinishedSpawning)
		{
			Collect(Player);
		}
		else
		{
			PendingCollectPlayer = Player;
			bPendingCollect = true;
		}
	}
};

class UMeltdownGlitchShootingPowerupEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Collect(FMeltdownGlitchShootingPowerupCollectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReachedGlitch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GlitchCreated() {}
};

struct FMeltdownGlitchShootingPowerupCollectParams
{
	UPROPERTY()
	FVector TargetLocation; 
}