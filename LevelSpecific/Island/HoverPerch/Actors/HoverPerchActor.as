struct FHoverPerchInstigatedMultiplier
{
	access Defaults = private, * (editdefaults);

	access:Defaults float BaseMultiplier = 1.0;
	private TMap<FInstigator, float> InstigatedMultipliers;

	void ApplyMultiplier(float Multiplier, FInstigator Instigator)
	{
		InstigatedMultipliers.Add(Instigator, Multiplier);
	}

	void ClearMultiplier(FInstigator Instigator)
	{
		InstigatedMultipliers.Remove(Instigator);
	}

	float GetValue() const property
	{
		float Multiplier = BaseMultiplier;
		for(auto Pair : InstigatedMultipliers)
		{
			Multiplier *= Pair.Value;
		}
		
		return Multiplier;
	}
}

event void FHoverPerchActivationSignature(AHazePlayerCharacter Player);
event void FHoverPerchGrindSwitchDirectionOnHitOtherPerch();
class AHoverPerchActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SwayRoot;

	UPROPERTY(DefaultComponent, Attach = SwayRoot)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.SpringStrength = 0.25;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollisionComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent BodyMeshComp;
	default BodyMeshComp.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent, Attach = SwayRoot)
	USceneComponent GrindSwitcherArrowRoot;

	UPROPERTY(DefaultComponent, Attach = SwayRoot, ShowOnActor)
	UPerchPointComponent PerchComp;
	default PerchComp.bShouldCameraFollowPointRotation = false;
	default PerchComp.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent, Attach = PerchComp)
	UPerchEnterByZoneComponent PerchEnterZone;

	UPROPERTY(DefaultComponent, Attach = SwayRoot)
	UNiagaraComponent TrailEffectComp;

	UPROPERTY(DefaultComponent)
	UHoverPerchMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncedPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchDashInputCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchGrindSplineCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchBlockMovementInputForJumpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchBlockRespawnForOtherPlayerWhileGrindingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchBumpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchDashCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchWorldCollisionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchHitObstacleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchHitObstacleBoostCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HoverPerchMovementInputCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedMeshRelativeRotation;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBodyMeshWorldRotation;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreActorCollisionComp;
	default GrenadeIgnoreActorCollisionComp.bAlsoIgnoreForGrenadeMovement = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;
	
	UPROPERTY(DefaultComponent)
	UHoverPerchComponent HoverPerchComp;

	UPROPERTY(DefaultComponent, Attach = SwayRoot)
	UNiagaraComponent ThrusterEffect;
	default ThrusterEffect.RelativeLocation = FVector(0, 0, -45);
	default ThrusterEffect.SetColorParameter(n"LinearColor", DefaultColor);
	default ThrusterEffect.SetFloatParameter(n"GlobalOpacity", 1.0);

	UPROPERTY(EditDefaultsOnly, Category = "Sway")
	FRuntimeFloatCurve IdleSwayCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Sway")
	FRuntimeFloatCurve LandingImpulseCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Sway")
	UHazeLocomotionFeatureBase HoverPerchFeature;

	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset GrindCameraSettings;

	UPROPERTY(EditAnywhere, Category = "Camera")
	TSubclassOf<UCameraShakeBase> GrindCameraShake;

	UPROPERTY(EditAnywhere, Category = "Shield Buster")
	UIslandRedBlueStickyGrenadeSettings GrenadeSettings;

	UPROPERTY(EditAnywhere, Category = "Force Feedback")
	float ForceFeedbackMultiplier = 1.0;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite)
	bool bShowTutorialPrompts = false;

	UPROPERTY(EditInstanceOnly, Category = "Sway")
	float IdleSwayHeightOffset = 20;

	UPROPERTY(EditInstanceOnly, Category = "Sway")
	float SwayDuration = 3;
	
	UPROPERTY(EditAnywhere, Category = "Sway")
	float LandingOffset = 20;

	UPROPERTY(EditAnywhere, Category = "Sway")
	float JumpOffOffset = 20;

	// How far away from the original Z the height reset speed will start decreasing from max speed to 0.
	UPROPERTY(EditAnywhere, Category = "Height")
	float ResetHeightFalloffDistance = 100.0;

	// When resetting the height, this will be the max speed
	UPROPERTY(EditAnywhere, Category = "Height")
	float ResetHeightMaxSpeed = 500.0;

	UPROPERTY(EditAnywhere, Category = "Dash")
	FRuntimeFloatCurve DashSpeedCurve;
	default DashSpeedCurve.AddDefaultKey(0, 5);
	default DashSpeedCurve.AddDefaultKey(0.5, 1.0);
	default DashSpeedCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditAnywhere, Category = "Dash")
	float DashSpeedMax = 1850.0;

	UPROPERTY(EditAnywhere, Category = "Dash")
	float DashDuration = 0.35;

	UPROPERTY(EditAnywhere, Category = "Dash")
	float DashCooldown = 0.4;

	UPROPERTY(EditAnywhere, Category = "Speed")
	float MaxSpeedWhileOnPerch = 750.0;
	
	UPROPERTY(EditAnywhere, Category = "Grind")
	float GrindSpeedMultiplierWhenHittingObstacle = 0.4;

	UPROPERTY(EditAnywhere, Category = "Grind")
	float GrindSpeedMultiplierAfterDestroyedObstacle = 1.5;

	UPROPERTY(EditAnywhere, Category = "Grind")
	float GrindSpeedMultiplierAfterDestroyedObstacleDuration = 0.8;

	UPROPERTY(EditAnywhere, Category = "Color")
	FLinearColor ZoeColor = FLinearColor(0.0, 0.48, 1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Color")
	FLinearColor MioColor = FLinearColor(1.00, 0.00, 0.00, 1.0);

	UPROPERTY(EditAnywhere, Category = "Color")
	FLinearColor DefaultColor = FLinearColor(1.00, 1.00, 1.00, 1.0);

	UPROPERTY(EditAnywhere, Category = "Color")
	float ColorChangeDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect WallImpactForceFeedback;

	UPROPERTY(EditAnywhere, Category = "Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> WallImpactCameraShake;

	UPROPERTY(EditAnywhere, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect BumpPlayerForceFeedback;

	UPROPERTY(EditAnywhere, Category = "Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> BumpPlayerCameraShake;

	UPROPERTY(EditAnywhere, Category = "Force Feedback & Camera Shake")
	UForceFeedbackEffect DashForceFeedback;

	UPROPERTY(EditAnywhere, Category = "Force Feedback & Camera Shake")
	TSubclassOf<UCameraShakeBase> DashCameraShake;

	UPROPERTY(EditAnywhere, Category = "Destruction Impulse")
	float DestructionUpImpulse = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Debug Drawing")
	bool bDebugDrawConnections = false;

	UPROPERTY()
	FHoverPerchGrindSwitchDirectionOnHitOtherPerch OnGrindSwitchDirectionOnHitOtherPerch;

	FSplinePosition PreviousGrindSplinePos;
	FSplinePosition GrindSplinePos;
	int NextGrindConnectionIndex = 0;

	float SwayTimer = 0;
	float LandingTimer = 0;
	float JumpOffTimer = 0;

	float LandingImpulseDuration = 2;
	float JumpOffImpulseDuration = 2;

	float TimeOfStartPerch = -100.0;
	float TimeOfStopPerch = -100.0;
	private float BaseZValue;
	TOptional<uint> FrameOfDashActionStarted;

	UPROPERTY(EditInstanceOnly)
	TArray<AHoverPerchResetLocation> ResetLocations;

	TArray<AHoverPerchGrindSpline> GrindsCloseEnoughToCheck;
	FHoverPerchInstigatedMultiplier InstigatedGrindSpeedMultiplier;
	AHoverPerchGrindSpline CurrentGrind;
	AHoverPerchGrindSpline ForcedGrind;
	bool bForcedGrindBackward;
	bool bSnapAnimationToMH = false;
	float PostDestroyObstacleBoostDurationRemaining = 0.0;
	FVector PreviousLocation;
	TOptional<uint> FrameOfSwitchGrindDirection;
	TInstigated<AActor> InstigatedCameraFocusActor;
	ARespawnPoint PreLockStickyRespawnPoint;

	AHazePlayerCharacter PlayerLocker;

	UTeleportResponseComponent TeleportResponseComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthComponent HealthComp;
	UHazeMovementComponent PlayerMoveComp;
	UPlayerPerchComponent PlayerPerchComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseZValue = ActorLocation.Z;

		PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerPerched");
		PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerching");
		ImpactCallbackComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnImpactByPlayer");
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetBaseZValue(float NewBaseZValue)
	{
		BaseZValue = NewBaseZValue;
	}

	float GetBaseZValue() const
	{
		return BaseZValue;
	}

	bool WasDashActionStarted() const
	{
		if(!FrameOfDashActionStarted.IsSet())
			return false;

		if(FrameOfDashActionStarted.Value != Time::FrameNumber)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HoverPerchComp.bIsGrinding)
		{
			SwayTimer += DeltaSeconds;

			if(SwayTimer > SwayDuration)
				SwayTimer -= SwayDuration;

			float SwayAlpha = SwayTimer / SwayDuration;
			FVector SwayOffset = FVector(0,0, IdleSwayHeightOffset * IdleSwayCurve.GetFloatValue(SwayAlpha));

			if(LandingTimer > 0)
			{
				LandingTimer -= DeltaSeconds;

				if(LandingTimer < 0)
					LandingTimer = 0;

				float LandingCurveAlpha = Math::GetMappedRangeValueClamped(FVector2D(LandingImpulseDuration, 0), FVector2D(0, 1), LandingTimer);
				SwayOffset += FVector::DownVector * (LandingOffset * LandingImpulseCurve.GetFloatValue(LandingCurveAlpha));
			}

			if(JumpOffTimer > 0)
			{
				JumpOffTimer -= DeltaSeconds;

				if(JumpOffTimer < 0)
					JumpOffTimer = 0;

				float JumpOffCurveAlpha = Math::GetMappedRangeValueClamped(FVector2D(JumpOffImpulseDuration, 0), FVector2D(0, 1), JumpOffTimer);
				SwayOffset += FVector::DownVector * (JumpOffOffset * LandingImpulseCurve.GetFloatValue(JumpOffCurveAlpha));
			}
			SwayRoot.SetRelativeLocation(SwayOffset);
		}
	}
	
	void ApplyHeightResetMovement(USweepingMovementData Movement, float DeltaTime)
	{
		if(Math::IsNearlyEqual(ActorLocation.Z, BaseZValue))
			return;

		float TotalDelta = BaseZValue - ActorLocation.Z;
		float SpeedAlpha = Math::Min(Math::Abs(TotalDelta), ResetHeightFalloffDistance) / ResetHeightFalloffDistance;
		float CurrentSpeed = ResetHeightMaxSpeed * SpeedAlpha;
		float CurrentDelta = CurrentSpeed * DeltaTime;
		CurrentDelta = Math::Min(CurrentDelta, Math::Abs(TotalDelta)) * Math::Sign(TotalDelta);

		Movement.AddDelta(FVector::UpVector * CurrentDelta);
	}

	UFUNCTION()
	void ApplyCameraFocusActor(AActor Actor, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedCameraFocusActor.Apply(Actor, Instigator, Priority);
	}

	UFUNCTION()
	void ClearCameraFocusActor(FInstigator Instigator)
	{
		InstigatedCameraFocusActor.Clear(Instigator);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerPerched(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		TEMPORAL_LOG(this, "Activation")
			.Value("Started Perching", true)
		;
		if(Player != HoverPerchComp.PerchingPlayer)
			NewPlayerStartedPerching(Player);

		UHoverPerchEffectHandler::Trigger_OnLandedOnPerch(this);

		HoverPerchComp.bHasHasImpactSincePerching = false;
	}

	private void NewPlayerStartedPerching(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		if(World.HasControl())
			CrumbPlayerStartedPerching(Player);
		else
		{
			LocalPlayerStartedPerching(Player);
			NetGuestTryToStartPerching(Player);
		}
	}

	UFUNCTION(NetFunction)
	private void NetGuestTryToStartPerching(AHazePlayerCharacter Player)
	{
		if(!World.HasControl())
			return;

		if(HoverPerchComp.PerchingPlayer != nullptr)
			return;
		
		LocalPlayerStartedPerching(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerStartedPerching(AHazePlayerCharacter Player)
	{
		// This should only happen in network, if perch is already occupied, kick them off and kill them.
		// Only happens if both players jump on the same perch at the same time. This will favor the host.
		if(Network::IsGameNetworked() && PlayerLocker != nullptr && PlayerLocker != Player)
		{
			AHazePlayerCharacter LockedPlayer = PlayerLocker;
			ClearPerchingPlayer(LockedPlayer);
			UnlockPerchToPlayer(LockedPlayer);

			if(PreLockStickyRespawnPoint != nullptr)
				LockedPlayer.SetStickyRespawnPoint(PreLockStickyRespawnPoint);

			LockedPlayer.KillPlayer();
		}

		LocalPlayerStartedPerching(Player);
	}

	// Run this on the remote side locally and then just unlock the perch if we aren't allowed. Otherwise the player can jump off the perch after sending the lock request.
	private void LocalPlayerStartedPerching(AHazePlayerCharacter Player)
	{
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		if(PlayerLocker == nullptr)
			LockPerchToPlayer(Player);

		TListedActors<AHoverPerchActor> HoverPerches;
		for(auto Perch : HoverPerches.Array)
		{
			if(Perch.HoverPerchComp.PerchingPlayer != nullptr &&
				Perch.HoverPerchComp.PerchingPlayer == Player)
				Perch.ClearPerchingPlayer();
		}

		HoverPerchComp.PerchingPlayer = Player;
		LandingTimer = LandingImpulseDuration;
		TimeOfStartPerch = Time::GetGameTimeSeconds();

		OnPerchActivated(Player);

		TrailEffectComp.Activate(false);
		
		PlayerPerchComp = UPlayerPerchComponent::Get(HoverPerchComp.PerchingPlayer);

		Player.ApplyCameraSettings(CameraSettings, 2, this, EHazeCameraPriority::Medium);
		Player.ApplySettings(GrenadeSettings, this);
	}

	private void ClearPerchingPlayer(AHazePlayerCharacter In_Player = nullptr)
	{
		AHazePlayerCharacter Player = In_Player;
		if(Player == nullptr)
			Player = HoverPerchComp.PerchingPlayer;
			
		OnPerchDeactivated(Player);
		TrailEffectComp.Deactivate();
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsOfClass(GrenadeSettings.Class, this);
		HoverPerchComp.PerchingPlayer = nullptr;
	}

	private void LockPerchToPlayer(AHazePlayerCharacter Player)
	{
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		PreLockStickyRespawnPoint = RespawnComp.StickyRespawnPoint;

		TListedActors<AHoverPerchActor> HoverPerches;
		for(auto Perch : HoverPerches.Array)
		{
			if(Perch.PlayerLocker == Player)
				Perch.UnlockPerchToPlayer(Player);
		}

		Player.AddLocomotionFeature(HoverPerchFeature, this);
		Player.BlockCapabilities(PlayerPerchPointTags::PerchPointJumpTo, this);
		Player.BlockCapabilities(PlayerMovementTags::WallRun, this);
		Player.BlockCapabilities(PlayerMovementTags::WallScramble, this);
		Player.BlockCapabilities(PlayerMovementTags::LedgeMantle, this);
		Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);

		if(Player.IsMio())
			PerchComp.SetUsableByPlayers(EHazeSelectPlayer::Mio);
		else
			PerchComp.SetUsableByPlayers(EHazeSelectPlayer::Zoe);

		FHoverPerchOnLockedToPerchEffectParams Params;
		Params.PlayerLocker = Player;

		UHoverPerchEffectHandler::Trigger_OnLockedToPlayer(this, Params);
		OnPerchLockedToPlayer(Player);

		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPerchingPlayerRespawn");
		HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeath");

		TeleportResponseComp = UTeleportResponseComponent::GetOrCreate(Player);
		TeleportResponseComp.OnTeleported.AddUFunction(this, n"OnPerchingPlayerTeleport");
		
		SetActorControlSide(Player);
		SyncedMeshRelativeRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		SyncedBodyMeshWorldRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		UHoverPerchPlayerComponent::GetOrCreate(Player).PerchActor = this;
		CapabilityInput::LinkActorToPlayerInput(this, Player);
		PlayerMoveComp.FollowComponentMovement(PerchComp, this);
		UPlayerAirMotionSettings::SetAirControlMultiplier(Player, 0.0, this);
		UPlayerAirMotionSettings::SetHorizontalMoveSpeed(Player, SMALL_NUMBER, this);
		UPlayerJumpSettings::SetHorizontalPerchImpulseMultiplier(Player, 0.0, this);
		UPlayerAirDashSettings::SetDashDistance(Player, 0.0, this);

		PlayerLocker = Player;
	}

	private void UnlockPerchToPlayer(AHazePlayerCharacter Player)
	{
 		Player.RemoveLocomotionFeature(HoverPerchFeature, this);
		Player.UnblockCapabilities(PlayerPerchPointTags::PerchPointJumpTo, this);
		Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);
		Player.UnblockCapabilities(PlayerMovementTags::WallScramble, this);
		Player.UnblockCapabilities(PlayerMovementTags::LedgeMantle, this);
		Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);

		PerchComp.SetUsableByPlayers(EHazeSelectPlayer::Both);

		UHoverPerchEffectHandler::Trigger_OnUnlockedFromPlayer(this);
		OnPerchUnlockedToPlayer(Player);

		RespawnComp.OnPlayerRespawned.Unbind(this, n"OnPerchingPlayerRespawn");
		HealthComp.OnDeathTriggered.Unbind(this, n"OnDeath");
		TeleportResponseComp.OnTeleported.Unbind(this, n"OnPerchingPlayerTeleport");

		SyncedMeshRelativeRotation.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
		SyncedBodyMeshWorldRotation.OverrideSyncRate(EHazeCrumbSyncRate::Standard);

		UHoverPerchPlayerComponent::GetOrCreate(Player).PerchActor = nullptr;
		PlayerMoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);

		Player.ClearSettingsByInstigator(this);
		PlayerLocker = nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPerchingPlayerRespawn(AHazePlayerCharacter Player)
	{
		if(HoverPerchComp.bIsDestroyed)
			UnDestroyHoverPerch();

		SetActorLocation(Player.ActorLocation);

		if(HasControl())
		{
			CrumbSetBaseZValue(Player.ActorLocation.Z);
			SyncedPositionComp.SnapRemote();
		}

		FHoverPerchOnPlayerRespawnedEffectParams EffectParams;
		EffectParams.PerchLocationAtRespawn = ActorLocation;
		UHoverPerchEffectHandler::Trigger_OnPlayerRespawnedWithPerch(this, EffectParams);

		OnPerchActivated(Player);
		bSnapAnimationToMH = true;
	}

	UFUNCTION()
	private void OnDeath()
	{
		DestroyHoverPerch(false, false);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPerchingPlayerTeleport()
	{
		if(HoverPerchComp.PerchingPlayer != nullptr)
			SetActorLocation(HoverPerchComp.PerchingPlayer.ActorLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerStoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		JumpOffTimer = JumpOffImpulseDuration;
		TimeOfStopPerch = Time::GetGameTimeSeconds();

		OnPerchDeactivated(Player);
		
		FHoverPerchOnJumpedFromPerchParams Params;
		Params.Player = Player;
		UHoverPerchEffectHandler::Trigger_OnJumpedFromPerch(this, Params);
	}

	UFUNCTION()
	private void OnImpactByPlayer(AHazePlayerCharacter Player)
	{
		if(PlayerLocker == nullptr)
			return;

		if(PlayerLocker == Player)
			return;

		FVector CenterToPlayerDir = (Player.ActorLocation - ActorCenterLocation).GetSafeNormal2D();
		Player.ApplyKnockdown(CenterToPlayerDir * 1500.0, 2.0);
	}

	UFUNCTION(BlueprintCallable)
	void SnapPlayerToHoverPerch(AHazePlayerCharacter Player)
	{
		auto Temp = UPlayerPerchComponent::Get(Player);
		Temp.StartPerching(PerchComp, true);
		bSnapAnimationToMH = true;
	}

	UFUNCTION(BlueprintCallable)
	void DestroyHoverPerch(bool bStopRespawning = false, bool bKillPlayer = true)
	{
		if(HasControl())
			CrumbDestroyHoverPerch(PlayerLocker, bStopRespawning, bKillPlayer);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbDestroyHoverPerch(AHazePlayerCharacter Player, bool bStopRespawning = false, bool bKillPlayer = true)
	{
		if(HoverPerchComp.bIsDestroyed)
		{
			// If this is destroyed we still want to stop respawning if calling again!
			if(bStopRespawning && Player != nullptr)
			{
				ClearPerchingPlayer(Player);
				UnlockPerchToPlayer(Player);
			}
			
			return;
		}

		SetActorVelocity(FVector::ZeroVector);

		ToggleVisuals(false);
		AddActorCollisionBlock(this);

		PerchComp.Disable(this);

		HoverPerchComp.bIsDestroyed = true;

		if(Player != nullptr)
		{
			if(bKillPlayer)
				Player.KillPlayer();
			else
			{
				FVector Impulse = MoveComp.PreviousVelocity;
				Impulse += FVector::UpVector * DestructionUpImpulse;
				Player.AddMovementImpulse(Impulse);
			}
		}
		if(bStopRespawning)
		{
			if(Player != nullptr)
			{
				ClearPerchingPlayer(Player);
				UnlockPerchToPlayer(Player);
			}
		}


		FHoverPerchDestroyedEffectParams EffectParams;
		EffectParams.PerchLocationAtDestruction = ActorLocation;
		UHoverPerchEffectHandler::Trigger_OnPerchDestroyed(this, EffectParams);
	}

	UFUNCTION(BlueprintCallable)
	void UnDestroyHoverPerch()
	{
		if(!HoverPerchComp.bIsDestroyed)
			return;
		
		RemoveActorCollisionBlock(this);
		ToggleVisuals(true);
		PerchComp.Enable(this);

		HoverPerchComp.bIsDestroyed = false;
	}

	void ToggleVisuals(bool bToggleOn)
	{
		if(bToggleOn)
		{
			MeshComp.RemoveComponentVisualsBlocker(this);
			BodyMeshComp.RemoveComponentVisualsBlocker(this);
			ThrusterEffect.RemoveComponentVisualsBlocker(this);
			Timer::SetTimer(this, n"ActivateTrailEffect", 0.85);
		}
		else
		{
			MeshComp.AddComponentVisualsBlocker(this);
			BodyMeshComp.AddComponentVisualsBlocker(this);
			ThrusterEffect.AddComponentVisualsBlocker(this);
			TrailEffectComp.Deactivate();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void ActivateTrailEffect()
	{
		TrailEffectComp.Activate(true);
	}

	FVector GetBaseLocation() const property
	{
		return ActorLocation - ActorUpVector * SphereCollisionComp.BoundsRadius * 0.5;
	}

	bool PlayerIsJumping() const
	{
		if(HoverPerchComp.PerchingPlayer == nullptr)
			return false;

		if(PlayerPerchComp.Data.bJumpingOff)
			return true;

		if(PlayerMoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintEvent)
	void OnPerchActivated(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnPerchDeactivated(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnPerchLockedToPlayer(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnPerchUnlockedToPlayer(AHazePlayerCharacter Player) {}
};