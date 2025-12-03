event void FDesertGrappleFishMountedSignature();

asset UDesertGrappleFishPlayerSheet of UHazeCapabilitySheet
{
	// PLAYER
	Capabilities.Add(UDesertGrappleFishPlayerMountCapability);
	Capabilities.Add(UDesertGrappleFishPlayerSteeringCapability);
	Capabilities.Add(UDesertGrappleFishRespawnBlockCapability);
	Capabilities.Add(UDesertGrappleFishPlayerRidingCapability);
	Capabilities.Add(UDesertGrappleFishPlayerOnSandDeathCapability);
	Capabilities.Add(UDesertGrappleFishPlayerCollisionDeathCapability);
	Capabilities.Add(UDesertGrappleFishJumpTutorialCapability);
	Capabilities.Add(UDesertGrappleFishPlayerCameraYawCapability);
	Capabilities.Add(UDesertGrappleFishPlayerAnimationCapability);
	Capabilities.Add(UDesertGrappleFishPlayerDeathCameraCapability);
	Capabilities.Add(UDesertGrappleFishPlayerDeadCapability);
}

asset UDesertGrappleFishSheet of UHazeCapabilitySheet
{
	// SHARK
	Capabilities.Add(UDesertGrappleFishNewMovementCapability);
	Capabilities.Add(UDesertGrappleFishRubberBandingCapability);
	Capabilities.Add(UDesertGrappleFishAutoPilotCapability);
	Capabilities.Add(UDesertGrappleFishPOIUpdateCapability);
	Capabilities.Add(UDesertGrappleFishEndJumpMovementCapability);
	Capabilities.Add(UDesertGrappleFishFollowSplineMovementCapability);

	Components.Add(UDesertGrappleFishComponent);
}

enum EDesertGrappleFishState
{
	Idle,
	Pulled,
	Waiting,
	Mounted,
	Stopped
}

struct FDesertGrappleFishAnimData
{
	UPROPERTY()
	bool bIsDiving = false;

	// Max Left == -1, Max Right == 1
	UPROPERTY()
	float TurnBlend = 0;

	UPROPERTY()
	bool bTriggerMioEndJump = false;

	UPROPERTY()
	bool bTriggerZoeEndJump = false;
}

class ADesertGrappleFish : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SharkRoot;

	UPROPERTY(DefaultComponent, BlueprintReadOnly, Attach = SharkRoot)
	UHazeCharacterSkeletalMeshComponent SharkMesh;

	UPROPERTY(DefaultComponent, Attach = SharkMesh, AttachSocket = "Neck")
	UDesertGrappleFishPerchPointComponent GrapplePointComp;
	default GrapplePointComp.bAllowAutoJumpTo = true;
	default GrapplePointComp.bAllowActivationWithinHeightMargin = true;
	default GrapplePointComp.HeightActivationMargin = 200;
	default GrapplePointComp.bBlockCameraEffectsForPoint = true;
	default GrapplePointComp.bAllowPerchCameraAssist = false;
	default GrapplePointComp.AdditionalGrappleRange = 1750;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(UDesertGrappleFishSheet);

	UPROPERTY(DefaultComponent, Attach = SharkMesh, AttachSocket = "Head")
	USceneComponent RopeAttachSocket;

	UPROPERTY(DefaultComponent, Attach = SharkMesh, AttachSocket = "Neck")
	USceneComponent RopePickupAttachSocket;

	// UPROPERTY(EditInstanceOnly)
	// ASandSharkSpline SplineActor;

	UPROPERTY(EditInstanceOnly)
	ASandSharkSpline AutoPilotSpline;

	UPROPERTY(EditInstanceOnly)
	ASandSharkSpline BoundarySpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor JumpSpline;

	UPROPERTY(EditInstanceOnly)
	bool bIsLeadFish;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent LogComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent, Attach = SharkRoot)
	USphereComponent SphereComp;
	default SphereComp.SphereRadius = 100;
	default SphereComp.GenerateOverlapEvents = true;
	default SphereComp.SetCollisionProfileName(n"OverlapAllDynamic");
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PlayerRidingMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LaunchAnim;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UPROPERTY(DefaultComponent)
	USceneComponent POITarget;

	UPROPERTY(EditAnywhere)
	ESandSharkLandscapeLevel LandscapeLevel = ESandSharkLandscapeLevel::Upper;

	UPROPERTY(EditInstanceOnly)
	ADesertGrappleFish OtherFish;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset RidingCameraSettings;

	UPROPERTY(DefaultComponent, Attach = SharkMesh)
	UHazeTEMPCableComponent CableComp;
	default CableComp.CableFriction = 3.0;

	UPROPERTY()
	FDesertGrappleFishMountedSignature OnMounted;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MovementShake;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor DeathCamera;

	UPROPERTY(EditAnywhere)
	ASplineActor DeathCameraSpline;

	AHazePlayerCharacter MountedPlayer;

	TInstigated<EDesertGrappleFishState> State;

	TInstigated<bool> InstigatedDive;
	TMap<FInstigator, bool> DiveInstigators;

	FSplinePosition AutoPilotSplinePosition;

	FVector ChaseTargetLocation;

	FVector Velocity;

	FVector CachedLandscapeNormal;
	uint FrameWhenFoundLandscapeNormal = 0;

	bool bHasRespawnOverride = false;

	UDesertGrappleFishPlayerComponent PlayerComp;

	FHazeAcceleratedFloat AccDive;

	float TimeWhenLastStartedDiving = 0;
	float TimeWhenStoppedDiving = 0;

	FHazeAcceleratedFloat AccTurnSpeed;

	UPlayerHealthComponent PlayerHealthComp;
	bool bHasBoundDeathEvent = false;

	bool bIsMovingTowardsEnd = false;
	bool bWantsToDive = false;
	bool bIsDiving = false;
	bool bForceAutoPilot;
	bool bAllowManualLaunch = true;
	bool bTriggerEndJump = false;
	bool bIsFollowingSpline = false;

	UDesertGrappleFishSplineCameraSettingsComponent CurrentSplineCameraSettingsComp;

	FDesertGrappleFishAnimData AnimData;
	AHazePlayerCharacter ControllingPlayer;

	float RubberbandAdditiveSpeed;

	FHazeAcceleratedVector AccMeshForward;
	FHazeAcceleratedVector AccLandscapeNormal;

	TInstigated<float> InstigatedMoveSpeed;
	default InstigatedMoveSpeed.DefaultValue = GrappleFishMovement::IdealMoveSpeed;

	UPROPERTY()
	float PlayerHorizontalInput;

#if EDITOR
	bool bIsDebuggingDive = false;
#endif
	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedMeshRotation;
	default SyncedMeshRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRootRotation;
	default SyncedRootRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	FHazeAcceleratedFloat AccMoveSpeed;

	float TimeWhenPlayerRespawned = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Network::IsGameNetworked())
			SetActorControlSide(GrapplePointComp.UsableByPlayers == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe);

		ControllingPlayer = GrapplePointComp.UsableByPlayers == EHazeSelectPlayer::Mio ? Game::Mio : Game::Zoe;

		GrappleFishMovement::AutoPilotCategory.MakeVisible();

		GrapplePointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPoint");
		GrapplePointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerching");
		GrapplePointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerching");
		AutoPilotSplinePosition = AutoPilotSpline.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);

		// Set these here as having them as default values does not work
		CableComp.SolverIterations = 30;
		CableComp.bEnableStiffness = true;
		CableComp.bSimulatePhysics = true;
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void TriggerDebugDive()
	{
		auto MioHealthComp = UPlayerHealthComponent::Get(Game::Mio);
		MioHealthComp.GodMode = EGodMode::God;
		auto ZoeHealthComp = UPlayerHealthComponent::Get(Game::Zoe);
		ZoeHealthComp.GodMode = EGodMode::God;

		auto MioComp = UDesertGrappleFishPlayerComponent::Get(Game::Mio);
		auto ZoeComp = UDesertGrappleFishPlayerComponent::Get(Game::Zoe);
		MioComp.LaunchFromGrappleFish();
		ZoeComp.LaunchFromGrappleFish();
		for (auto GrappleFish : TListedActors<ADesertGrappleFish>())
		{
			GrappleFish.DebugDive();
			Timer::SetTimer(GrappleFish, n"ClearDiving", 0.5);
		}
		FHazePointOfInterestFocusTargetInfo MioInfo;
		MioInfo.SetFocusToActor(MioComp.GrappleFish);

		FHazePointOfInterestFocusTargetInfo ZoeInfo;
		ZoeInfo.SetFocusToActor(ZoeComp.GrappleFish);
		FApplyPointOfInterestSettings Settings;
		Settings.Duration = 1;
		Game::Mio.ApplyPointOfInterest(this, MioInfo, Settings, 2, EHazeCameraPriority::Debug);
		Game::Zoe.ApplyPointOfInterest(this, ZoeInfo, Settings, 2, EHazeCameraPriority::Debug);
	}

	UFUNCTION()
	private void ClearDiving()
	{
		AnimData.bIsDiving = false;
	}

	void DebugDive()
	{
		AnimData.bIsDiving = true;
		bIsDebuggingDive = true;
		bIsDiving = true;
	}
#endif
	void AttachRopeToPlayer()
	{
		if (ControllingPlayer.IsZoe())
			CableComp.SetAttachEndToComponent(ControllingPlayer.Mesh, n"RightAttach");
		else
			CableComp.SetAttachEndToComponent(ControllingPlayer.Mesh, n"LeftAttach");

		CableComp.SolverIterations = 30;
		CableComp.bEnableStiffness = true;
		CableComp.bSimulatePhysics = true;
	}

	void DetachRopeFromPlayer()
	{
		CableComp.SetAttachEndToComponent(RopePickupAttachSocket);
		CableComp.SolverIterations = 30;
		CableComp.bEnableStiffness = true;
		CableComp.bSimulatePhysics = true;
	}

	bool HasRider() const
	{
		return MountedPlayer != nullptr;
	}

	bool IsRiderAlive() const
	{
		return !ControllingPlayer.IsPlayerDead() && !ControllingPlayer.IsPlayerRespawning();
	}

	bool HasAutoPilotOverride()
	{
#if EDITOR
		if (HasAliveAutoPilotDebug() || HasDeadAutoPilotDebug())
			return true;
#endif

		return bForceAutoPilot;
	}

#if EDITOR
	bool HasAliveAutoPilotDebug()
	{
		if (ControllingPlayer.IsMio())
			return GrappleFishMovement::MioAutoPilotAlive.IsEnabled();
		else
			return GrappleFishMovement::ZoeAutoPilotAlive.IsEnabled();
	}

	bool HasDeadAutoPilotDebug()
	{
		if (ControllingPlayer.IsMio())
			return GrappleFishMovement::MioAutoPilotDead.IsEnabled();
		else
			return GrappleFishMovement::ZoeAutoPilotDead.IsEnabled();
	}
#endif

	UFUNCTION()
	void ForceAutoPilot()
	{
		bForceAutoPilot = true;
		PlayerComp.MakePlayerUnstable();
	}

	float GetMovementSpeed() const
	{
		if (bIsDiving)
			return InstigatedMoveSpeed.Get();
		else
			return InstigatedMoveSpeed.Get() + RubberbandAdditiveSpeed;
	}

	UFUNCTION()
	void TeleportGrapplefishToPositionClosestToActor(AActor Actor)
	{
		SetActorLocationAndRotation(Actor.ActorLocation, Actor.ActorRotation);
		AutoPilotSplinePosition = AutoPilotSpline.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		MoveComp.Reset();
	}

	bool CanPlayerRespawnOnFish()
	{
		if (GrapplePointComp.IsDisabledForPlayer(ControllingPlayer))
			return false;

		return true;
	}

	void AddDiveInstigator(FInstigator Instigator)
	{
		InstigatedDive.Apply(true, Instigator, EInstigatePriority::High);
		DiveInstigators.Add(Instigator, true);
	}

	void ClearDiveInstigator(FInstigator Instigator)
	{
		InstigatedDive.Clear(Instigator);
		if (DiveInstigators.Contains(Instigator))
			DiveInstigators.Remove(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (PlayerComp != nullptr && PlayerComp.State != EDesertGrappleFishPlayerState::Riding)
		{
			FTransform NeckTransform = PlayerComp.GrappleFish.SharkMesh.GetSocketTransform(n"Spine3");
			FVector Up = NeckTransform.Rotation.Rotator().ForwardVector;
			GrapplePointComp.WorldLocation = NeckTransform.Location + Up * 155;
		}

#if EDITOR
		TEMPORAL_LOG(this)
			.DirectionalArrow("ForwardVector", ActorLocation, ActorForwardVector * 1000, 5, 30, FLinearColor::LucBlue)
			.Value("PlayerHorizontalInput", PlayerHorizontalInput)
			.Sphere("ActorLocation", ActorLocation, 100, GrapplePointComp.UsableByPlayers == EHazeSelectPlayer::Mio ? PlayerColor::Mio : PlayerColor::Zoe, 5)
			.Value("ActorHeight", ActorLocation.Z)
			.Value("State", State.Get())
			.Value("bIsDiving", bIsDiving)
			.Value("BaseMovementSpeed", GrappleFishMovement::IdealMoveSpeed)
			.Value("RubberbandAdditiveSpeed", RubberbandAdditiveSpeed)
			.Value("CurrentMovementSpeed", AccMoveSpeed.Value)
			.Value("CurrentMovementDesiredSpeed", GetMovementSpeed())
			.Sphere("AutoSplinePosition", AutoPilotSplinePosition.WorldLocation, 250, ControllingPlayer.IsMio() ? PlayerColor::Mio : PlayerColor::Zoe);
#endif
	}

	UFUNCTION()
	private void OnPlayerStoppedPerching(AHazePlayerCharacter Player,
								 UPerchPointComponent PerchPoint)
	{
		if (bHasBoundDeathEvent)
		{
			PlayerHealthComp.OnDeathTriggered.Unbind(this, n"OnPlayerDeathTriggered");
			bHasBoundDeathEvent = false;
		}
		// MountedPlayer = nullptr;
	}

	void HandleDismount()
	{
		MountedPlayer = nullptr;
		Dive();
		// PlayerComp.RemoveRideCameraInstigator(this);
	}

	void Dive()
	{
		bIsDiving = true;
		AnimData.bIsDiving = true;
		GrapplePointComp.Disable(this);
		InstigatedMoveSpeed.Apply(GrappleFishMovement::DivingStartedMoveSpeed, n"DivingStartedSpeed", EInstigatePriority::Normal);
		UDesertGrappleFishEventHandler::Trigger_OnStopSwimming(this);
		UDesertGrappleFishEventHandler::Trigger_OnDiveStarted(this);
	}
	void Resurface()
	{
		AnimData.bIsDiving = false;
		Timer::SetTimer(this, n"EnableGrapple", 0.35);
		InstigatedMoveSpeed.Clear(n"DivingStartedSpeed");
		UDesertGrappleFishEventHandler::Trigger_OnStartSwimming(this);
	}

	UFUNCTION()
	private void EnableGrapple()
	{
		bIsDiving = false;
		GrapplePointComp.Enable(this);
	}

	UFUNCTION()
	private void OnPlayerStartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (PlayerComp == nullptr)
		{
			PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
			PlayerComp.GrappleFish = this;
		}

		MountedPlayer = Player;
		PlayerComp.ChangeState(EDesertGrappleFishPlayerState::Riding);
		OnMounted.Broadcast();

		ApplyRespawnOverride();

		if (State.Get() == EDesertGrappleFishState::Mounted)
			return;

		PlayerComp.GrappleFish = this;
	}

	void ApplyRespawnOverride()
	{
		if (!bHasRespawnOverride)
		{
			bHasRespawnOverride = true;
			UPlayerRespawnComponent::Get(ControllingPlayer).ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"HandlePlayerRespawn"), EInstigatePriority::Normal);
		}
	}

	UFUNCTION()
	void ClearRespawnOverride(AHazePlayerCharacter Player)
	{
		UPlayerRespawnComponent::Get(Player).ClearRespawnOverride(this);
	}

	UFUNCTION()
	void StopMoving()
	{
		State.Apply(EDesertGrappleFishState::Stopped, this, EInstigatePriority::Override);
		PlayerComp.LaunchFromGrappleFish();
	}

	UFUNCTION(DevFunction)
	void KillPlayers()
	{
		Game::Mio.KillPlayer();
		Game::Zoe.KillPlayer();
	}

	UFUNCTION()
	private void OnPlayerInitiatedGrappleToPoint(AHazePlayerCharacter Player,
										 UGrapplePointBaseComponent GrapplePoint)
	{
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		PlayerComp.ChangeState(EDesertGrappleFishPlayerState::Grappling);
		PlayerComp.GrappleFish = this;
		// PlayerComp.AddRideCameraInstigator(this);
		Player.StopSlotAnimationByAsset(LaunchAnim);

		if (PlayerHealthComp == nullptr)
		{
			PlayerHealthComp = UPlayerHealthComponent::Get(Player);
			PlayerHealthComp.OnDeathTriggered.AddUFunction(this, n"OnPlayerDeathTriggered");
			bHasBoundDeathEvent = true;
		}

		if (PlayerComp.bTutorialStarted)
			PlayerComp.bTutorialCompleted = true;
	}

	UFUNCTION()
	private void OnPlayerDeathTriggered()
	{
		// PlayerComp.RemoveRideCameraInstigator(this);
		PlayerComp.ChangeState(EDesertGrappleFishPlayerState::None);
	}

	UFUNCTION()
	private bool HandlePlayerRespawn(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation)
	{
		if (GrapplePointComp.IsDisabledForPlayer(RespawningPlayer))
			return false;

		if (PlayerComp == nullptr)
		{
			PlayerComp = UDesertGrappleFishPlayerComponent::Get(RespawningPlayer);
			PlayerComp.GrappleFish = this;
		}

		if (PlayerHealthComp == nullptr)
		{
			PlayerHealthComp = UPlayerHealthComponent::Get(RespawningPlayer);
			PlayerHealthComp.OnDeathTriggered.AddUFunction(this, n"OnPlayerDeathTriggered");
			bHasBoundDeathEvent = true;
		}
		
		UPlayerGrappleComponent PlayerGrappleComp = UPlayerGrappleComponent::Get(ControllingPlayer);
		if (PlayerGrappleComp != nullptr)
			PlayerGrappleComp.Data.ForceGrapplePoint = nullptr;

		PlayerComp.ChangeState(EDesertGrappleFishPlayerState::None);
		Perch::TeleportPlayerOntoPerch(RespawningPlayer, this, GrapplePointComp);
		TimeWhenPlayerRespawned = Time::GameTimeSeconds;
		// RespawningPlayer.SnapCameraBehindPlayer();
		return true;
	}

	void ClearMountedPlayer()
	{
		GrapplePointComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
		GrapplePointComp.SetVisibility(true);
	}

	UFUNCTION()
	void SetManualLaunchAllowed(bool bAllowed)
	{
		bAllowManualLaunch = bAllowed;
	}

	void TriggerEndJump()
	{
		bTriggerEndJump = true;
	}
};