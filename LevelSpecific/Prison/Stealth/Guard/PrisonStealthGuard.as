asset PrisonStealthGuardSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPrisonStealthGuardMoveCapability);
	Capabilities.Add(UPrisonStealthGuardPatrolSplineCapability);
	Capabilities.Add(UPrisonStealthGuardPatrolWaitCapability);
	Capabilities.Add(UPrisonStealthGuardSearchCapability);
	Capabilities.Add(UPrisonStealthGuardStunnedCapability);

	Capabilities.Add(UPrisonStealthVisionCapability);
	Capabilities.Add(UPrisonStealthDetectionCapability);
	Capabilities.Add(UPrisonStealthShootPlayerCapability);
	Capabilities.Add(UPrisonStealthEnemyEventsCapability);
};

event void FStealthGuardSplineEndReached(APrisonStealthGuard Guard, ASplineActor SplineActor);

/**
 * A guard, either standing still or following a spline.
 * Can be shot by the Sniper Turret.
 * Can visually detect Magnet player.
 */
UCLASS(Abstract, HideCategories = "Collision Rendering Activation Cooking Actor")
class APrisonStealthGuard : APrisonStealthEnemy
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent ImpactSpringComp;

	UPROPERTY(DefaultComponent, Attach = ImpactSpringComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UPrisonStealthVisionComponent VisionComp;

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	USceneComponent TurretPosition;

	UPROPERTY(DefaultComponent, Attach = TurretPosition)
	UNiagaraComponent BeamVFX;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(PrisonStealthGuardSheet);

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent ResponseComponent;

	UPROPERTY(DefaultComponent)
	UPrisonStealthStunnedComponent StunnedComp;

	UPROPERTY(DefaultComponent)
	UPrisonStealthGuardPatrolComponent PatrolComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedActorPosition.SyncRate = EHazeCrumbSyncRate::Standard;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EPrisonStealthGuardState GuardState;

	FVector TargetLocation;
	float InitialYaw;
	float TargetYaw;

	/**
	 * Searching
	 */

	// How long (in seconds) should the guard stop and search for the player? This is time from the last time the player was spotted.
	UPROPERTY(EditAnywhere, Category = "Searching")
	float SearchTime = 1.0;

	// How smoothly to follow the rotation of the search swiveling. Lower values means more loose, and higher is more snappy.
	float SearchRotateInterpSpeed = 10.0;

	UPROPERTY(EditAnywhere, Category = "Hit")
	float HitImpulse = 500;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SpotLight.SetVisibility(GuardState == EPrisonStealthGuardState::Enabled);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ResponseComponent.OnHackableSniperTurretHit.AddUFunction(this, n"OnHitBySniperTurret");

		// Make sure to default TargetLocation as this will be used for interpolation
		InitialYaw = GetActorRotation().Yaw;

		TargetLocation = GetActorLocation() - FVector(0.0, 0.0, PatrolComponent.DistanceFromGround);
		TargetYaw = InitialYaw;

		SpotLight.SetVisibility(false);
		
		SetGuardState(GuardState, bTriggerEffect = false);	// Initialize state
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		FTemporalLog GuardSection = TemporalLog.Section("Guard", 0);
		GuardSection.Value("Current Section Index", PatrolComponent.CurrentSectionIndex);
		GuardSection.Value("Guard State", GuardState);
		GuardSection.Value("Target Location", TargetLocation);
		GuardSection.Value("Target Yaw", TargetYaw);
		GuardSection.Value("Stunned Until Time", StunnedComp.GetStunnedUntilTime());

		for(auto Player : Game::Players)
		{
			if(!IsDetectionEnabledForPlayer(Player))
				continue;

			FPrisonStealthPlayerLastSeen LastSeenData = GetLastSeenData(Player);
			FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
			FTemporalLog PlayerSection = TemporalLog.Section(PlayerName, int(Player.Player) + 1);
			
			PlayerSection.Sphere("Last Seen Location", LastSeenData.Location, MagnetDrone::Radius);
			PlayerSection.Value("Last Seen Time", LastSeenData.Time);
			PlayerSection.Value("Current Time", Time::GetGlobalCrumbTrailTime());

			UPrisonStealthDetectionComponent DetectionComp = DetectionComponents[Player];
			PlayerSection.Value("Player Is In Sight", DetectionComp.IsPlayerInSight());
			PlayerSection.Value("Has Detected Player", DetectionComp.HasDetectedPlayer());
			PlayerSection.Value("Detection Alpha", DetectionComp.GetDetectionAlpha());
		}
#endif
	}

	UFUNCTION()
	void SetGuardState(EPrisonStealthGuardState InGuardState, bool bTriggerEffect = true)
	{
		GuardState = InGuardState;

		if(IsCapabilityTagBlocked(PrisonStealthTags::StealthGuard))
			UnblockCapabilities(PrisonStealthTags::StealthGuard, this);

		RemoveActorVisualsBlock(this);

		switch(GuardState)
		{
			case EPrisonStealthGuardState::Enabled:
				break;

			case EPrisonStealthGuardState::Disabled:
				BlockCapabilities(PrisonStealthTags::StealthGuard, this);
				break;

			case EPrisonStealthGuardState::Invisible:
				BlockCapabilities(PrisonStealthTags::StealthGuard, this);
				AddActorVisualsBlock(this);
				break;

			default:
				check(false);	// Unhandled case
				break;
		}

		if(bTriggerEffect)
		{
			FPrisonStealthGuardOnGuardStateChangedParams Params;
			Params.GuardState = InGuardState;
			UPrisonStealthGuardEventHandler::Trigger_OnGuardStateChanged(this, Params);
		}
	}

	UFUNCTION()
	void OnHitBySniperTurret(FHackableSniperTurretHitEventData EventData)
	{
		if(StunnedComp.IsStunned())
		{
			FPrisonStealthGuardOnStunStartedParams Params;
			Params.bReset = true;
			UPrisonStealthGuardEventHandler::Trigger_OnStunStarted(this, Params);
		}

		StunnedComp.StartStun();
		PrisonStealth::GetStealthManager().OnGuardHit(this);

		FVector ImpulseDirection = Math::Lerp(EventData.TraceDirection, -EventData.ImpactNormal, 0.5);
		ImpulseDirection = ImpulseDirection.GetSafeNormal(ResultIfZero = EventData.TraceDirection);

		ImpactSpringComp.ApplyImpulse(EventData.ImpactPoint, ImpulseDirection * HitImpulse);
	}

	void Reset() override
	{
		Super::Reset();

		UPrisonStealthGuardEventHandler::Trigger_OnReset(this);
	}
};