
event void FOnBallBossLostChargeLaser(int Index = 0);

class ASkylineBallBoss : AHazeActor
{
	UPROPERTY(EditAnywhere, Category = "Attackers")
	TMap<ESkylineBallBossAttacker, AActor> Attackers;
	default Attackers.Add(ESkylineBallBossAttacker::CarSmash1, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::CarSmash2, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::Bike1, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::Bike2, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::Bike3, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::Bike4, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::Bike5, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::RollingBus, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::SlidingCar3, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::SlidingCar4, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::SlidingCar5, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::SlidingCar6, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::DetonatorSpawner1, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::DetonatorSpawner2, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::DetonatorSpawner3, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::MotorcycleManager, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::LobbingCar1, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::LobbingCar2, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::LobbingCar3, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::LobbingCar4, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::LobbingCar5, nullptr);
	default Attackers.Add(ESkylineBallBossAttacker::LobbingCar6, nullptr);
	
	UPROPERTY(DefaultComponent)
	USkylineBallBossActionsComponent ActionsComp;
	bool bHasThrownBus = false;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent BecomeSmallBossQueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent TelegraphEyeQueueComp;

	UPROPERTY(Transient)
	ASkylineBallBossBigLaser BigLaserActor = nullptr;

	UPROPERTY(Transient, BlueprintReadOnly)
	private ESkylineBallBossPhase Phase = ESkylineBallBossPhase::Top;

	UPROPERTY(EditAnywhere)
	FSkylineBallBossChaseSplineEvent OnSplineChaseEvent;

	UPROPERTY(EditAnywhere)
	TMap<FName, ASkylineBallBossChaseSpline> EventSplines;
	FName EventSplineID;

	UPROPERTY(EditInstanceOnly)
	TArray<ASkylineBallBossChaseSpline> ChaseSplines;
	int ChaseSplineIndex = 0;

	UPROPERTY(EditInstanceOnly)
	ASkylineGravityRespawnPoint InsideRespawnPoint;

	UPROPERTY(EditAnywhere)
	bool bChaseSnapToBehindPlayers = false;

	bool bChaseStarted = false;
	UPROPERTY(BlueprintReadOnly)
	bool bHasDoneFakout = false;

	UPROPERTY(EditDefaultsOnly)
	float ChaseStartWaitTime = 5.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SkylineBallBossDefaultSheet);
	default CapabilityComp.DefaultSheets.Add(SkylineBallBossActionSelectionSheet);
	default CapabilityComp.DefaultSheets.Add(SkylineBallBossPositionActionSelectionSheet);
	bool bIsInTearOffPositioning = false;

	UPROPERTY(DefaultComponent, RootComponent)
	private USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ImpactLocationOffsetComp;

	UPROPERTY(DefaultComponent, Attach = ImpactLocationOffsetComp)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = "Base")
	USceneComponent FakeRootComp;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UDeathVolumeComponent ZoeDeathSphereComp;
	default ZoeDeathSphereComp.TriggeredByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeDeathSphereComp.Shape = FHazeShapeSettings::MakeSphere(1200);

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyeMeshCompUnbroken;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyeMeshCompBroken1;
	default EyeMeshCompBroken1.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyeMeshCompFullyBroken;
	default EyeMeshCompFullyBroken.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent LightsEyeMeshComp;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyePanelPart1;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyePanelPart2;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyePanelPart3;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyePanelPart4;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyePanelPart5;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent HatchFrameMeshComp;
	default HatchFrameMeshComp.SetVisibility(false);

	UPROPERTY(DefaultComponent, Attach = HatchFrameMeshComp)
	USkylineBallBossDetonatorSocketComponent DetonatorSocketComp1;
	UPROPERTY(DefaultComponent, Attach = DetonatorSocketComp1)
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp1;

	UPROPERTY(DefaultComponent, Attach = HatchFrameMeshComp)
	USkylineBallBossDetonatorSocketComponent DetonatorSocketComp2;
	UPROPERTY(DefaultComponent, Attach = DetonatorSocketComp2)
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp2;

	UPROPERTY(DefaultComponent, Attach = HatchFrameMeshComp)
	USkylineBallBossDetonatorSocketComponent DetonatorSocketComp3;
	UPROPERTY(DefaultComponent, Attach = DetonatorSocketComp3)
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp3;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	USceneComponent SceneLaserWeakspotComponent;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyeLidLowerMeshComp;
	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent EyeLidUpperMeshComp;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent ShieldShockwave;
	default ShieldShockwave.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UStaticMeshComponent DisintegrationSphere;
	default DisintegrationSphere.CollisionEnabled = ECollisionEnabled::NoCollision;
	float DisintegrationRadius = 0.0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance EmberEyePanelMaterial0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance EmberEyePanelMaterial1;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance RedLampEyePanelMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance RedLampPulseEyePanelMaterial;
	bool bHasResetMaterials = true;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance NormalLampEyePanelMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance BrokenLampEyePanelMaterialA;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance BrokenLampEyePanelMaterialB;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance NormalLampPulseEyePanelMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance BrokenLampPulseEyePanelMaterialA;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance BrokenLampPulseEyePanelMaterialB;

	int FaceHurtStage = 0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance LightsOutMaterial;

	UPROPERTY(EditAnywhere)
	FLinearColor ShieldColor = ColorDebug::Cerulean;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShieldRadiusTimelike;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShieldAlphaTimelike;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DisintegratePulseRadiusTimelike;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DisintegratePulseAlphaTimelike;

	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	FHazeTimeLike RemoveDetonatorBlinkOpenTimelike;
	default RemoveDetonatorBlinkOpenTimelike.UseSmoothCurveZeroToOne();
	default RemoveDetonatorBlinkOpenTimelike.bCurveUseNormalizedTime = true;
	default RemoveDetonatorBlinkOpenTimelike.Duration = 0.2;

	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	FHazeTimeLike RemoveDetonatorBlinkCloseTimelike;
	default RemoveDetonatorBlinkCloseTimelike.UseLinearCurveOneToZero();
	default RemoveDetonatorBlinkCloseTimelike.bCurveUseNormalizedTime = true;
	default RemoveDetonatorBlinkCloseTimelike.Duration = 0.1;

	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	float RemoveBlinkFirstOpenDuration = 0.1;
	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	float MinRandPauseDuration = 0.4;
	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	float MaxRandPauseDuration = 1.0;
	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	int MinRandBlinks = 2;
	UPROPERTY(EditAnywhere, Category = "Blink Remove Detonator")
	int MaxRandBlinks = 2;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	USceneComponent HatchLocationComp;
	
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem TractorBeamVFXAsset;

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityShiftComponent;
	default GravityShiftComponent.bForceSticky = false;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UGravityBladeGrappleComponent GrappleComponent;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleResponseComponent GrappleResponseComponent;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UPlayerInheritMovementComponent InheritMovementComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 1;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
	#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	USkylineBallBossInstigatorTokenComponent AttackBlinkTokenComp;

	UPROPERTY(DefaultComponent)
	USkylineBallBossFocusPlayerComponent FocusPlayerComponent;

	UPROPERTY(EditInstanceOnly)
	ASkylineBallBossStageActor OnStageActor;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset FakeoutCameraSettings;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor FakeOutCamera;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor TrailerFakeoutCamera;

	UPROPERTY()
	UHazeCameraSettingsDataAsset OnBallBossCamSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset InBallBossCamSettings;

	UPROPERTY()
	UPlayerCameraSettings RemovePivotLagCameraSettings;

	UPROPERTY()
	FBallBossPhaseChanged OnPhaseChanged;

	UPROPERTY()
	UNiagaraSystem AttackedOnShieldVFXSystem;

	UPROPERTY()
	UNiagaraSystem MioShieldJumpVFXSystem;

	UPROPERTY()
	UNiagaraSystem MioShieldGravityChangeVFXSystem;

	UPROPERTY()
	UNiagaraSystem BreakEyeVFXSystem;

	UPROPERTY()
	UMaterialInterface HatchFrameBrokenMaterial;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossAttachedDetonator> AttachedDetonatorClass;

	UPROPERTY()
	UForceFeedbackEffect ZoeTearingWeakpointFF;

	UPROPERTY()
	UForceFeedbackEffect ZoeTornOffWeakpointFF;

	UPROPERTY()
	UForceFeedbackEffect NoCritMioFF;

	UPROPERTY()
	UForceFeedbackEffect CritMioFF;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> ObjectSmallDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ObjectSmallDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> ObjectLargeDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ObjectLargeDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> ExplosionDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ExplosionDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> LaserSoftDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> LaserSoftDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> LaserHeavyDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> LaserHeavyDeathEffect;

	UPROPERTY(DefaultComponent, Attach = FakeRootComp)
	USphereComponent ActivateInsideTrigger;
	bool bInsideActivated = false;

	UPROPERTY(EditAnywhere)
	bool bTrailerProgressPoint = false;

	UPROPERTY(EditInstanceOnly)
	ASkylineBallBossPostChaseBlocker BlockPlayersPostChaseElevator;

	UPROPERTY()
	FMioReachedInside OnMioReachedInside;

	UPROPERTY()
	FMioReachedOutside OnMioReachedOutside;

	UPROPERTY()
	FBallBossDied OnBallBossDied;

	UPROPERTY()
	FBallBossCritEvent OnBallBossCritFlickerStart;

	UPROPERTY()
	FBallBossCritEvent OnBallBossCritFlickerEnd;

	UPROPERTY()
	FBallBossCritEvent OnBallBossCritSolidStart;
	int SolidCritStacks = 0;

	UPROPERTY()
	FBallBossCritEvent OnBallBossCritSolidEnd;

	UPROPERTY()
	FBallBossTelegraphEyeStart OnTelegraphEyeStart;
	UPROPERTY()
	FBallBossTelegraphEyeStop OnTelegraphEyeStop;

	UPROPERTY()
	FBallBossChaseLaserSplineChanged OnChaseLaserSplineChanged;

	TArray<ASkylineBallBossChargeLaser> ChargeLasers;
	FOnBallBossLostChargeLaser OnBallBossLostChargeLaser;
	ASkylineBallBossWeakpoint Weakpoint;

	FHazeAcceleratedVector AcceleratedTargetVector;
	FHazeAcceleratedQuat AcceleratedTargetRotation;

	FHazeAcceleratedVector AcceleratedOffsetVector;
	FHazeAcceleratedQuat AcceleratedOffsetQuat;

	bool bExtraSlowRotateToZoe = false;

	TArray<FBallBossShieldEffectData> ShieldVFXDatas;
	TArray<FBallBossAlignRotationData> AlignTowardsStageDatas;
	FVector SnapTargetLocation;
	TArray<FInstigator> FreezeRotationRequesters;
	TArray<FInstigator> FreezeLocationRequesters;
	TArray<FInstigator> DisableAttacksRequesters;
	FGravityWhipImpactData ImpactRotation;
	bool bHasSnapRotation = false;
	bool bRecentlyLostWeakpoint = false;
	bool bRecentlyGotDetonated = false;
	bool bFlashShield = false;
	bool bSwingLaser = false;
	int NumLaserSwings = 0;
	bool bDisabledMoveOverride = false;
	float ChangedPhaseDramaticPauseTimestamp = -1.0;
	bool bTriggerDisintegrationPulse = false;
	bool bShowingPanel = false;
	bool bHasSetupPhase = false;
	bool bDebugging = false;
	bool bDebuggingRotation = false;
	bool bDebuggingMovement = false;
	bool bBrokenEye = false;

	private TArray<FBallBossBlink> Blinks;
	
	float AttackSwitchExpressionCooldown = 2.1;
	float AttackSwitchExpressionTimestamp = 0.0;

	float TargetHeight = 0.0;
	float ChaseDistanceAfterEventSpline = 0.0;

	int SpawnedObjects = 0;
	int NumMissedGrapples = 0;

	bool bIsInChaseTrailerLaser = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		UBasicAIHealthBarSettings::SetHealthBarSegments(this, Settings.HealthSegments, this);

		// make sure things are parented to FakeRootComp, not Root
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false);
		for (auto AttachedActor : AttachedActors)
		{
			AttachedActor.AttachToComponent(FakeRootComp, NAME_None, EAttachmentRule::KeepWorld);
		}

		GravityShiftComponent.bEnableAutoShift = false;
		InheritMovementComponent.DisableTriggerForPlayer(Game::Mio, this);
		InheritMovementComponent.DisableTriggerForPlayer(Game::Zoe, this);

#if EDITOR
		TArray<USceneComponent> Children;
		Root.GetChildrenComponents(false, Children);
		for (auto Child : Children)
		{
			if (Child != ImpactLocationOffsetComp)
			{
				devError(f"Please attach {Child.GetName()} to SkylineBallBoss FakeRootComp instead of Root!");
			}
		}
#endif

		ActivateInsideTrigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		ImpactResponseComp.OnImpact.AddUFunction(this, n"HandleImpact");
		GrappleResponseComponent.OnPullStart.AddUFunction(this, n"HandleGrappleStarted");
		GrappleResponseComponent.OnPullEnd.AddUFunction(this, n"HandleGrappleEnded");
		OnBallBossDied.AddUFunction(this, n"HandleDied");

		Game::Mio.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		Game::Zoe.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		Game::Mio.BlockCapabilities(n"GravityBladeCombatCamera", this);
		Game::Mio.ApplySettings(RemovePivotLagCameraSettings, this);

		OnBallBossLostChargeLaser.AddUFunction(this, n"HandleLostChargeLaser");

		ResetTarget();

		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::OnlyShowWhenHurt, this);

		TargetHeight = ActorLocation.Z;
		OnSplineChaseEvent.AddUFunction(this, n"SplineEventTriggered");
		AcceleratedTargetRotation.SnapTo(ActorQuat);

		AddBlink(this, ESkylineBallBossBlinkExpression::StateSus, ESkylineBallBossBlinkPriority::Lowest);

		//Setup events for player death
		for (auto Player : Game::GetPlayers())
		{
			auto PlayerHealthComp = UPlayerHealthComponent::GetOrCreate(Player);
			PlayerHealthComp.OnStartDying.AddUFunction(this, n"HandlePlayerDeath");
		}
	}

	UFUNCTION()
	private void HandlePlayerDeath()
	{
		if (!Game::Zoe.IsPlayerDead())
		{
			FSkylineBallBossKilledPlayerEventHandlerParams Params;
			Params.Player = Game::Mio;
			USkylineBallBossMiscVOEventHandler::Trigger_BallBossKilledPlayer(this, Params);
		}
		else if (!Game::Mio.IsPlayerDead())
		{
			FSkylineBallBossKilledPlayerEventHandlerParams Params;
			Params.Player = Game::Zoe;
			USkylineBallBossMiscVOEventHandler::Trigger_BallBossKilledPlayer(this, Params);
		}
		else
			USkylineBallBossMiscVOEventHandler::Trigger_BallBossWon(this);
	}

	UFUNCTION()
	private void HandleDied()
	{
		HealthBarComp.RemoveHealthBars();
	}

	UFUNCTION()
	private void HandleLostChargeLaser(int Index)
	{
		BP_LostLaser(Index);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_LostLaser(int Index){}

	UFUNCTION()
	void RemoveFrontPanel()
	{
		UnstickMioToBall();
		GravityShiftComponent.bEnableAutoShift = false;
		Game::Mio.ClearCameraSettingsByInstigator(this);
		UPlayerHealthComponent::Get(Game::Zoe).TriggerRespawn(false);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_RemoveFrontPanel(){}

	UFUNCTION()
	private void SplineEventTriggered(ESkylineBallBossChaseEventType EventType, FSkylineBallBossChaseSplineEventData EventData)
	{
		if (SkylineBallBossDevToggles::DrawChaseEvents.IsEnabled())
			PrintToScreen("Chase Spline Event: " + EventType, 10.0, ColorDebug::Yellow);

		if (EventType == ESkylineBallBossChaseEventType::NextChaseSpline)
		{
			ProceedToNextSpline();
			return;
		}

		if (EventType == ESkylineBallBossChaseEventType::EventSpline)
		{
			ChaseDistanceAfterEventSpline = EventData.SplineDistance;
			ProceedToEventSpline(EventData.Text);
			return;
		}

		if (EventType == ESkylineBallBossChaseEventType::OverrideSpeed)
		{
			GetCurrentChaseSpline().OverrideLaserSpeed = EventData.Float;
			return;
		}

		if (EventType == ESkylineBallBossChaseEventType::OverrideHeight)
		{
			TargetHeight = EventData.Float; 
			return;
		}

		if (EventType == ESkylineBallBossChaseEventType::TrapPlayersOnElevator)
		{
			if (BlockPlayersPostChaseElevator != nullptr)
				BlockPlayersPostChaseElevator.ForcePlayersIntoElevator();
			return;
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetUseFakeoutSpline()
	{
		// DEPRECATED
	}

	bool HasChaseSpline()
	{
		return ChaseSplineIndex < ChaseSplines.Num();
	}

	void ProceedToEventSpline(FName EventSplineName)
	{
		if (!ensure(EventSplines.Contains(EventSplineName), "Couldn't find event spline with name " + EventSplineName))
			return;
		EventSplineID = EventSplineName;
		OnChaseLaserSplineChanged.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void SetStartSplineIndexForProgressPoint(int SplineIndex)
	{
		ChaseSplineIndex = SplineIndex;
	}

	void ProceedToNextSpline()
	{
		if (HasControl())
			CrumbProceedToNextSpline();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbProceedToNextSpline()
	{
		EventSplineID = n"";
		++ChaseSplineIndex;
		OnChaseLaserSplineChanged.Broadcast();
	}

	ASkylineBallBossChaseSpline GetCurrentChaseSpline(bool bAllowEventSpline = true)
	{
		if (bAllowEventSpline && !EventSplineID.IsNone())
			return EventSplines[EventSplineID];
		if (ChaseSplines.Num() <= ChaseSplineIndex)
			return nullptr;
		return ChaseSplines[ChaseSplineIndex];
	}

	void AddCritEffect(bool MioFeedback = true)
	{
		DamageEyeMesh();
		
		OnBallBossCritSolidStart.Broadcast();
		++SolidCritStacks;
		Timer::SetTimer(this, n"RemoveSolidCrit", 1.0);
		if (MioFeedback && CritMioFF != nullptr)
			Game::Mio.PlayForceFeedback(CritMioFF, false, false, this);
	}

	UFUNCTION()
	void RemoveSolidCrit()
	{
		--SolidCritStacks;
		if (SolidCritStacks == 0)
			OnBallBossCritSolidEnd.Broadcast();
	}

	void AddNoCritEffect(FVector WorldLocation)
	{
		// if (AttackedOnShieldVFXSystem != nullptr)
		// {
		// 	FBallBossShieldEffectData Data;
		// 	Data.VFXComp = Niagara::SpawnLoopingNiagaraSystemAttachedAtLocation(AttackedOnShieldVFXSystem, HatchFrameMeshComp, WorldLocation);
		// 	ShieldVFXDatas.Add(Data);
		// }
		if (NoCritMioFF != nullptr)
			Game::Mio.PlayForceFeedback(NoCritMioFF, false, false, this);
	}

	void LogRotationTargets()
	{
#if EDITOR
		for (int i = 0; i < AlignTowardsStageDatas.Num(); ++i) 
		{
			FBallBossAlignRotationData TargetData = AlignTowardsStageDatas[i];
			FString NumberString = "" + i;
			TEMPORAL_LOG(this, "RotationTargets").Value(NumberString + "Part", TargetData.PartComp);
			TEMPORAL_LOG(this, "RotationTargets").Value(NumberString + "OverridePart", TargetData.OverrideTargetComp);
			TEMPORAL_LOG(this, "RotationTargets").Value(NumberString + "LocalDirection", TargetData.BallLocalDirection);
			TEMPORAL_LOG(this, "RotationTargets").Value(NumberString + "HeightOffset", TargetData.HeightOffset);
			TEMPORAL_LOG(this, "RotationTargets").Value(NumberString + "ContinouousUpdate", TargetData.bContinuousUpdate);
		}
#endif
	}

	int NumRotationTargets() const
	{
		return AlignTowardsStageDatas.Num();
	}

	bool HasRotationTarget(AActor PartOwner)
	{
		for (int i = 0; i < AlignTowardsStageDatas.Num(); ++i)
		{
			bool bHasPartComp = AlignTowardsStageDatas[i].PartComp != nullptr && AlignTowardsStageDatas[i].PartComp.Owner == this;
			bool bHasOverrideTarget = AlignTowardsStageDatas[i].OverrideTargetComp != nullptr;
			if (bHasPartComp || bHasOverrideTarget)
				return true;
		}
		return false;
	}

	FBallBossAlignRotationData GetCurrentRotationTarget()
	{
		EBallBossAlignRotationDataPrio HighestPrio = EBallBossAlignRotationDataPrio::Lowest;
		int PrioIndex = 0;
		for (int i = 0; i < AlignTowardsStageDatas.Num(); ++i) 
		{
			FBallBossAlignRotationData TargetData = AlignTowardsStageDatas[i];
			if (TargetData.Priority > HighestPrio)
				PrioIndex = i;
		}
		return AlignTowardsStageDatas[PrioIndex];
	}

	void AddRotationTarget(FBallBossAlignRotationData Data)
	{
		AlignTowardsStageDatas.Add(Data);
	}

	void RemoveRotationTarget(USceneComponent SceneComp)
	{
		for (int i = 0; i < AlignTowardsStageDatas.Num(); ++i) 
		{
			FBallBossAlignRotationData TargetData = AlignTowardsStageDatas[i];
			if (TargetData.IsPartOrTarget(SceneComp))
			{
				AlignTowardsStageDatas.RemoveAt(i);
				break;
			}
		}
	}

	FVector GetBallBossForwardTargetVector()
	{
		return FakeRootComp.WorldLocation + ActorForwardVector * 2000.0;
	}

	FVector GetAsBallBossTargetVector(FVector WorldLocation)
	{
		FVector Diff = (WorldLocation - FakeRootComp.WorldLocation).GetSafeNormal();
		return FakeRootComp.WorldLocation + Diff * 2000.0;
	}

	void ResetTarget()
	{
		AcceleratedTargetVector.SnapTo(GetBallBossForwardTargetVector());
	}

	UFUNCTION(BlueprintPure)
	ESkylineBallBossPhase GetPhase() const
	{
		return Phase;
	}

	UFUNCTION(BlueprintCallable)
	void ChangePhase(ESkylineBallBossPhase NewPhase)
	{
		ESkylineBallBossPhase PreviousPhase = Phase;
		Phase = NewPhase;
		OnPhaseChanged.Broadcast(Phase);
		ActionsComp.ActionQueue.Reset();
		UpdateDramaticPause();
		UpdateHealthBarVisibility();

		NumMissedGrapples = 0;

		if (Phase == ESkylineBallBossPhase::TopMioOff2)
			Game::Mio.ClearCameraSettingsByInstigator(this);

		if (Phase > ESkylineBallBossPhase::Chase)
			BigLaserActor.CollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		// if (Phase == ESkylineBallBossPhase::TopMioInKillWeakpoint)
		// 	Weakpoint.RemoveShield();

		FSkylineBallBossChangedPhaseEventHandlerParams EventParams;
		EventParams.NewPhase = NewPhase;
		USkylineBallBossEventHandler::Trigger_ChangedPhase(this, EventParams);

		ResetLampMaterials();

		if (Phase == ESkylineBallBossPhase::TopSmallBoss)
		{
			// if (PreviousPhase == ESkylineBallBossPhase::TopMioInKillWeakpoint)
			// {
				BecomeSmallBossQueueComp.Idle(0.1);
				BecomeSmallBossQueueComp.Event(this, n"BP_RemoveFrontPanel");
				BecomeSmallBossQueueComp.Idle(1.1);
				BecomeSmallBossQueueComp.Event(this, n"SelfDisable");
			// }
			// else
			// {
			// 	BecomeSmallBossQueueComp.Event(this, n"SelfDisable");
			// }
			OnBallBossDied.Broadcast();
			Game::Mio.ClearCameraSettingsByInstigator(this);
		}
	}

	UFUNCTION()
	private void SelfDisable()
	{
		Weakpoint.AddActorDisable(this);
		AddActorDisable(this);
	}

	private void UpdateDramaticPause()
	{
		if (!bHasSetupPhase)
		{
			bHasSetupPhase = true;
			return;
		}
		if (Phase == ESkylineBallBossPhase::TopMioOn1)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopMioOn1;
		if (Phase == ESkylineBallBossPhase::TopGrappleFailed1)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopGrappleFailed1;
		if (Phase == ESkylineBallBossPhase::TopAlignMioToStage)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopAlignMioToStage;
		if (Phase == ESkylineBallBossPhase::TopShieldShockwave)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopShieldShockwave;
		if (Phase == ESkylineBallBossPhase::TopMioOff2)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopMioOff2;
		if (Phase == ESkylineBallBossPhase::TopMioOn2)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopMioOn2;
		if (Phase == ESkylineBallBossPhase::TopGrappleFailed2)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopGrappleFailed2;
		if (Phase == ESkylineBallBossPhase::TopMioIn)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopMioIn;
		if (Phase == ESkylineBallBossPhase::TopMioInKillWeakpoint)
			ChangedPhaseDramaticPauseTimestamp = Settings.PauseTopMioInKillWeakpoint;
		
		if (ChangedPhaseDramaticPauseTimestamp > -KINDA_SMALL_NUMBER)
			ChangedPhaseDramaticPauseTimestamp += Time::GameTimeSeconds;
	}

	private void SetupHealth(float NewHealth)
	{
		UpdateHealthBarVisibility();
		HealthComp.SetCurrentHealth(NewHealth);
		HealthBarComp.UpdateHealthBarSettings();
	}

	private void UpdateHealthBarVisibility()
	{
		if (Phase >= ESkylineBallBossPhase::Top)
		{
			UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
			HealthBarComp.UpdateHealthBarVisibility();
		}
	}

	UFUNCTION()
	void SetupChase()
	{
		bChaseStarted = true;
		ChangePhase(ESkylineBallBossPhase::Chase);
	}

	UFUNCTION()
	void SetupOffBallBoss1()
	{
		ChangePhase(ESkylineBallBossPhase::Top);
	}

	UFUNCTION()
	void SetupOnBallBoss1()
	{
		MioReachedOutside();
		GravityShiftComponent.bEnableAutoShift = true;
		ChangePhase(ESkylineBallBossPhase::TopMioOn1);
	}

	UFUNCTION()
	void SetupBallBossMioShockwave()
	{
		MioReachedOutside();
		ChangePhase(ESkylineBallBossPhase::TopAlignMioToStage);
		SetupHealth(Settings.SegmentHealth * 3.0);
		DamageEyeMesh();
	}

	UFUNCTION()
	void SetupOffBallBoss2()
	{
		ChangePhase(ESkylineBallBossPhase::TopMioOff2);
		SetupHealth(Settings.SegmentHealth * 3.0);
		DamageEyeMesh();
	}

	UFUNCTION()
	void SetupOnBallBoss2()
	{
		MioReachedOutside();
		GravityShiftComponent.bEnableAutoShift = true;
		ChangePhase(ESkylineBallBossPhase::TopMioOn2);
		SetupHealth(Settings.SegmentHealth * 3.0);
		DamageEyeMesh();
	}

	UFUNCTION()
	void SetupInBallBoss()
	{
		MioReachedOutside();
		BreakEye(false);
		EnableInsideGravity();
		GravityShiftComponent.bEnableAutoShift = true;
		SetupHealth(Settings.SegmentHealth * 2.0);
	}

	UFUNCTION()
	void SetupInBallBossKillWeakpoint()
	{
		float DesiredHealth = HealthComp.MaxHealth * Settings.WeakpointHealth;
		SetupHealth(DesiredHealth);
		MioReachedOutside();
		BreakEye(false);
		EnableInsideGravity();

		ChangePhase(ESkylineBallBossPhase::TopMioInKillWeakpoint);
		TArray<AActor> AttachedActors;
		for (int iChargeLaser = 0; iChargeLaser < ChargeLasers.Num(); ++iChargeLaser)
		{
			ChargeLasers[iChargeLaser].GetAttachedActors(AttachedActors, true, true);
			for (auto AttachedActor : AttachedActors)
			{
				AttachedActor.SetActorHiddenInGame(true);
				AttachedActor.AddActorDisable(this);
				AttachedActor.SetAutoDestroyWhenFinished(true);
			}
			ChargeLasers[iChargeLaser].SetActorHiddenInGame(true);
			ChargeLasers[iChargeLaser].AddActorDisable(this);
			ChargeLasers[iChargeLaser].SetAutoDestroyWhenFinished(true);
		}
		ChargeLasers.Empty();
	}

	UFUNCTION()
	void SetupFinisherBallBoss()
	{
		ChangePhase(ESkylineBallBossPhase::TopDeath);
		HealthBarComp.RemoveHealthBars();
		GrappleComponent.Disable(this);
		StickMioToBall();
		BreakEye(false);
		EnableInsideGravity();
	}

	UFUNCTION()
	void SetupSmallBossBallBoss()
	{
		ChangePhase(ESkylineBallBossPhase::TopSmallBoss);
		HealthBarComp.RemoveHealthBars();
		GrappleComponent.Disable(this);
		BreakEye(false);
	}


	void StickMioToBall()
	{
		GravityShiftComponent.bForceSticky = true;
		InheritMovementComponent.EnableTriggerForPlayer(Game::Mio, this);
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Game::Mio);
		if (bDisabledMoveOverride)
			MoveComp.ClearFollowEnabledOverride(this);
		bDisabledMoveOverride = false;
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled, EInstigatePriority::High);
	}

	void UnstickMioToBall()
	{
		GravityShiftComponent.bForceSticky = false;
		GrappleComponent.Enable(this);
		GravityShiftComponent.bEjectPlayer = true;
		UGravityBladeGrappleEjectComponent MioEjectComp = UGravityBladeGrappleEjectComponent::GetOrCreate(Game::Mio);
		if (!MioEjectComp.OnEjectComplete.IsBound())
			MioEjectComp.OnEjectComplete.AddUFunction(this, n"EjectDone");
		
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Game::Mio);
		MoveComp.ClearFollowEnabledOverride(this);
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowDisabled, EInstigatePriority::High);
		bDisabledMoveOverride = true;
		Game::Mio.ApplyBlendToCurrentView(3.0);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Game::Mio);
	}

	UFUNCTION()
	void EjectDone()
	{
		GravityShiftComponent.bEnableAutoShift = false;
		GravityShiftComponent.bEjectPlayer = false;
		InheritMovementComponent.DisableTriggerForPlayer(Game::Mio, this);
	}

	bool MioIsOnBall()
	{
		return GravityShiftComponent.bForceSticky;
	}

	UFUNCTION()
	private void HandleGrappleStarted(UGravityBladeGrappleUserComponent GrappleComp)
	{
		MioReachedOutside();
		if (Phase == ESkylineBallBossPhase::Top || Phase == ESkylineBallBossPhase::TopGrappleFailed1)
			ChangePhase(ESkylineBallBossPhase::TopMioOn1);
		else if (Phase == ESkylineBallBossPhase::TopMioOff2 || Phase == ESkylineBallBossPhase::TopGrappleFailed2)
			ChangePhase(ESkylineBallBossPhase::TopMioOn2);

		FBallBossAlignRotationData AlignData;
		GravityShiftComponent.bEnableAutoShift = true;
		AlignData.PartComp = GrappleComponent;
		AlignData.OverrideTargetComp = Game::Mio.RootComponent;
		AlignData.bAccelerateAlignTowardsTarget = false;
		AlignData.HeightOffset = 0.0;
		AlignData.bUseRandomOffset = false;
		AlignTowardsStageDatas.Add(AlignData);
		if (BigLaserActor.bActive)
			BigLaserActor.DeactivateLaser();
		bExtraSlowRotateToZoe = true;
	}

	UFUNCTION()
	private void HandleGrappleEnded(UGravityBladeGrappleUserComponent GrappleComp)
	{
		RemoveRotationTarget(Game::Mio.RootComponent);
	}

	UFUNCTION()
	private void MioReachedOutside()
	{
		Game::Mio.ApplyCameraSettings(OnBallBossCamSettings, 2.0, this, EHazeCameraPriority::High);
		GrappleComponent.Disable(this);
		OnMioReachedOutside.Broadcast();
		StickMioToBall();
	}

	UFUNCTION()
	private void HandleImpact(FGravityWhipImpactData ImpactData)
	{
		if (!Network::IsGameNetworked() || Game::Zoe.HasControl())
		{
			ASkylineBallBossThrowableDetonator ThrowableDetonator = Cast<ASkylineBallBossThrowableDetonator>(ImpactData.ThrownActor);
			if (ThrowableDetonator == nullptr || ThrowableDetonator.DibbedSocket == nullptr)
				return;
			
			SpawnDetonator(ImpactData.HitResult.ImpactPoint, ThrowableDetonator.DibbedSocket);
		}
		ImpactRotation = ImpactData;
	}

	private void SpawnDetonator(FVector Location, USkylineBallBossDetonatorSocketComponent DibbedSocket)
	{
		if (Phase != ESkylineBallBossPhase::TopMioOn1 && Phase != ESkylineBallBossPhase::TopMioOn2)
			return;
		FVector RelativeLocation = ImpactLocationOffsetComp.WorldTransform.InverseTransformPosition(Location);
		CrumbSpawnDetonator(RelativeLocation, DibbedSocket);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnDetonator(FVector RelativeLocation, USkylineBallBossDetonatorSocketComponent DibbedSocket)
	{
		if (DibbedSocket == nullptr)
			return;

		FVector NewRelativeLocation = RelativeLocation;
		NewRelativeLocation = ImpactLocationOffsetComp.WorldTransform.InverseTransformPosition(DibbedSocket.WorldLocation);

		auto SpawnedActor = SpawnActor(AttachedDetonatorClass, FVector::ZeroVector, FRotator::ZeroRotator, NAME_None, true);
		SpawnedActor.MakeNetworked(this, SpawnedObjects);
		SpawnedObjects++;
		SpawnedActor.SetActorControlSide(Game::Mio);
		FinishSpawningActor(SpawnedActor);
		SpawnedActor.AttachToComponent(FakeRootComp, NAME_None, EAttachmentRule::SnapToTarget);
		SpawnedActor.SetActorRelativeLocation(NewRelativeLocation);
		SpawnedActor.SetActorRotation((SpawnedActor.ActorLocation - ActorLocation).Rotation());
		SpawnedActor.BallBoss = this;
		// always spawn attached at this point
		{
			DibbedSocket.bSpawningAttached = false;
			DibbedSocket.AttachedDetonator = SpawnedActor;
			SpawnedActor.DibbedSocket = DibbedSocket;
		}
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
			EnableInsideGravity();
	}

	void DamageEyeMesh()
	{
		if (bBrokenEye)
			return;
		EyeMeshCompUnbroken.SetHiddenInGame(true);
		EyeMeshCompBroken1.SetHiddenInGame(false);
	}

	UFUNCTION()
	void BreakEye(bool bDisintegrateLingeringDetonators)
	{
		if (bDisintegrateLingeringDetonators)
			bTriggerDisintegrationPulse = true;
		bBrokenEye = true;
		EyeMeshCompUnbroken.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		EyeMeshCompUnbroken.SetHiddenInGame(true);
		EyeMeshCompBroken1.SetHiddenInGame(true);
		EyeMeshCompFullyBroken.SetHiddenInGame(false);
		HatchFrameMeshComp.SetMaterial(0, HatchFrameBrokenMaterial);
		AddBlink(this, ESkylineBallBossBlinkExpression::StateOpen, ESkylineBallBossBlinkPriority::High);

		if (Phase < ESkylineBallBossPhase::TopMioIn)	
			Niagara::SpawnOneShotNiagaraSystemAttached(BreakEyeVFXSystem, HatchLocationComp);
	}

	UFUNCTION()
	void EnableInsideGravity()
	{
		if (bInsideActivated)
			return;
		
		bInsideActivated = true;
		GravityShiftComponent.bInvertDirection = true;
		Game::Mio.ApplyCameraSettings(InBallBossCamSettings, 2.0, this, EHazeCameraPriority::VeryHigh);

		if (Phase != ESkylineBallBossPhase::TopDeath)
		{
			OnMioReachedInside.Broadcast();
			ChangePhase(ESkylineBallBossPhase::TopMioIn);
			// PrintToScreen("EnabledInside " + Phase, 4.0);
		}
	}

	USkylineBallBossSettings GetSettings() property
	{
		return Cast<USkylineBallBossSettings>(
			GetSettings(USkylineBallBossSettings)
		);
	}

	float GetBossRadius()
	{
		return HatchLocationComp.RelativeLocation.X;
	}

	const ESkylineBallBossBlinkExpression GetBlink()
	{
		ESkylineBallBossBlinkPriority HighestPrio = ESkylineBallBossBlinkPriority::Unassigned;
		ESkylineBallBossBlinkExpression Expression = ESkylineBallBossBlinkExpression::StateOpen;
		for (FBallBossBlink Blink : Blinks)
		{
			if (Blink.Priority > HighestPrio)
			{
				HighestPrio = Blink.Priority;
				Expression = Blink.BlinkType;
			}
		}
		return Expression;
	}

	void DebugPrintBlinks()
	{
		for (int i = 0; i < Blinks.Num(); ++i)
		{
			FBallBossBlink Blink = Blinks[i];
			FVector WorldOffset = FVector::UpVector * 100.0 * i;
			Debug::DrawDebugString(HatchFrameMeshComp.WorldLocation + WorldOffset, "" + Blink.Priority + " / " + Blink.BlinkType + " , " + Blink.Requester.ToString());
		}
	}

	void AddBlink(FInstigator Requester, ESkylineBallBossBlinkExpression BlinkType, ESkylineBallBossBlinkPriority Priority)
	{
		FBallBossBlink Data;
		Data.BlinkType = BlinkType;
		Data.Requester = Requester;
		Data.Priority = Priority;
		Blinks.Add(Data);
	}

	void RemoveBlink(FInstigator Requester, ESkylineBallBossBlinkExpression BlinkType)
	{
		FBallBossBlink ThingToRemove;
		for (FBallBossBlink Blink : Blinks)
		{
			if (Blink.Requester == Requester && Blink.BlinkType == BlinkType)
			{
				ThingToRemove = Blink;
				break;
			}
		}
		Blinks.Remove(ThingToRemove);
	}

	void RemoveBlink(FInstigator Requester)
	{
		FBallBossBlink ThingToRemove;
		for (FBallBossBlink Blink : Blinks)
		{
			if (Blink.Requester == Requester)
			{
				ThingToRemove = Blink;
				break;
			}
		}
		Blinks.Remove(ThingToRemove);
	}

	void ShowPanel()
	{
		if (!bShowingPanel)
		{
			bShowingPanel = true;
			FBallBossAlignRotationData AlignData;
			AlignData.BallLocalDirection = -FVector::ForwardVector;
			AlignData.OverrideTargetComp = OnStageActor.RootComponent;
			AlignData.bContinuousUpdate = true;
			AlignData.bSnapOverTime = true;
			AlignTowardsStageDatas.Add(AlignData);

			float PanelWindow = 3.0;//0.6;
			// if (GetPhase() == ESkylineBallBossPhase::TopGrappleFailed1 || GetPhase() == ESkylineBallBossPhase::TopGrappleFailed2)
			// {
			// 	++NumMissedGrapples;
			// 	PanelWindow = Math::Clamp(1.0 * NumMissedGrapples, 0.6, 8.0);
			// }

			FSkylineBallBossShowPanelEventHandlerParams EventParams;
			EventParams.Phase = GetPhase();
			EventParams.ShowDuration = PanelWindow;
			USkylineBallBossEventHandler::Trigger_ShowPanel(this, EventParams);

			Timer::SetTimer(this, n"StopShowPanel", PanelWindow);
			ActionsComp.ActionQueue.Reset();
			FSkylineBallBossActionIdleData IdleData;
			IdleData.Duration = PanelWindow;
			ActionsComp.ActionQueue.Queue(IdleData);
		}
	}

	UFUNCTION()
	private void StopShowPanel()
	{
		if (bShowingPanel)
		{
			bShowingPanel = false;
			RemoveRotationTarget(OnStageActor.RootComponent);
			if (!MioIsOnBall())
			{
				if (GetPhase() == ESkylineBallBossPhase::Top)
					ChangePhase(ESkylineBallBossPhase::TopGrappleFailed1);
				else if (GetPhase() == ESkylineBallBossPhase::TopMioOff2)
					ChangePhase(ESkylineBallBossPhase::TopGrappleFailed2);
			}
		}
	}

	bool ShouldHaveBrokenEyeA() const
	{
		return FaceHurtStage >= 4;
	}

	bool ShouldHaveBrokenEyeB() const
	{
		return FaceHurtStage >= 5;
	}

	const int LampBaseBlinkIndex = 1;
	const int LampBrokenBlinkIndexA = 6;
	const int LampBrokenBlinkIndexB = 7;

	const int LampBasePulseIndex = 4;
	const int LampBrokenPulseIndexA = 8;
	const int LampBrokenPulseIndexB = 9;


	UFUNCTION()
	void ResetLampMaterials()
	{
		LightsEyeMeshComp.SetMaterial(LampBasePulseIndex, NormalLampPulseEyePanelMaterial);
		LightsEyeMeshComp.SetMaterial(LampBaseBlinkIndex, NormalLampEyePanelMaterial);
		if (ShouldHaveBrokenEyeA())
		{
			LightsEyeMeshComp.SetMaterial(LampBrokenPulseIndexA, BrokenLampPulseEyePanelMaterialA);
			LightsEyeMeshComp.SetMaterial(LampBrokenBlinkIndexA, BrokenLampEyePanelMaterialA);
		}
		else
		{
			LightsEyeMeshComp.SetMaterial(LampBrokenPulseIndexA, NormalLampPulseEyePanelMaterial);
			LightsEyeMeshComp.SetMaterial(LampBrokenBlinkIndexA, NormalLampEyePanelMaterial);
		}
		if (ShouldHaveBrokenEyeB())
		{
			LightsEyeMeshComp.SetMaterial(LampBrokenPulseIndexB, BrokenLampPulseEyePanelMaterialB);
			LightsEyeMeshComp.SetMaterial(LampBrokenBlinkIndexB, BrokenLampEyePanelMaterialB);
		}
		else
		{
			LightsEyeMeshComp.SetMaterial(LampBrokenPulseIndexB, NormalLampPulseEyePanelMaterial);
			LightsEyeMeshComp.SetMaterial(LampBrokenBlinkIndexB, NormalLampEyePanelMaterial);
		}
	}

	private void SetMaterialOnValidLamps(UMaterialInstance BlinkLampMaterial, UMaterialInstance PulseLampMaterial)
	{
		LightsEyeMeshComp.SetMaterial(LampBasePulseIndex, PulseLampMaterial);
		LightsEyeMeshComp.SetMaterial(LampBaseBlinkIndex, BlinkLampMaterial);
		// don't change away from broken materials
		if (!ShouldHaveBrokenEyeA())
		{
			LightsEyeMeshComp.SetMaterial(LampBrokenPulseIndexA, PulseLampMaterial);
			LightsEyeMeshComp.SetMaterial(LampBrokenBlinkIndexA, BlinkLampMaterial);
		}
		if (!ShouldHaveBrokenEyeB())
		{
			LightsEyeMeshComp.SetMaterial(LampBrokenPulseIndexB, PulseLampMaterial);
			LightsEyeMeshComp.SetMaterial(LampBrokenBlinkIndexB, BlinkLampMaterial);
		}
	}

	UFUNCTION()
	void PulseOn()
	{
		SetMaterialOnValidLamps(RedLampEyePanelMaterial, RedLampPulseEyePanelMaterial);
	}

	UFUNCTION()
	void PanikEyeOff()
	{
		//SetMaterialOnValidLamps(NormalLampEyePanelMaterial, NormalLampPulseEyePanelMaterial);
		ResetLampMaterials();
	}

	UFUNCTION()
	void PanikEyeOn()
	{
		SetMaterialOnValidLamps(RedLampEyePanelMaterial, RedLampPulseEyePanelMaterial);
	}

	UFUNCTION(BlueprintCallable)
	void DisableBossForDefeatCutscene(FInstigator Instigator)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for (AActor Actor : AttachedActors)
		{
			Actor.SetActorHiddenInGame(true);
			Actor.AddActorDisable(Instigator);
		}
		SetActorHiddenInGame(true);
		AddActorDisable(Instigator);
	}

	// -------------------------
	// DBEUGGING STUFF

	UFUNCTION()
	void SetupDebugTopOff()
	{
		SetupOffBallBoss1();
		SetupDebug();
	}

	UFUNCTION()
	void SetupDebugTopOn()
	{
		SetupOnBallBoss1();
		SetupDebug();
	}

	UFUNCTION()
	void SetupDebugTopInside()
	{
		SetupInBallBoss();
		SetupDebug();
	}

	private void SetupDebug()
	{
#if EDITOR
		bDebugging = true;
		// ToggleFreezeRotation();
		// ToggleFreezeLocation();
		ToggleDisableAttacks();
#endif
	}

#if EDITOR
	UFUNCTION(DevFunction)
	private void TestShieldJump()
	{
		bool Phase1 = GetPhase() == ESkylineBallBossPhase::TopMioOn1 || GetPhase() == ESkylineBallBossPhase::TopGrappleFailed1;
		if (Phase1)
		{
			float Damage = HealthComp.CurrentHealth - Settings.DamageRequiredToActivateShield;
			HealthComp.TakeDamage(Damage, EDamageType::Default, this);
			ChangePhase(ESkylineBallBossPhase::TopAlignMioToStage);
		}
	}

	UFUNCTION(DevFunction)
	private void ToggleFreezeRotation()
	{
		if (FreezeRotationRequesters.Contains(this))
			FreezeRotationRequesters.Remove(this);
		else
			FreezeRotationRequesters.Add(this);
	}

	UFUNCTION(DevFunction)
	private void ToggleFreezeLocation()
	{
		if (FreezeLocationRequesters.Contains(this))
			FreezeLocationRequesters.Remove(this);
		else
			FreezeLocationRequesters.Add(this);
	}

	UFUNCTION(DevFunction)
	private void ToggleDisableAttacks()
	{
		if (DisableAttacksRequesters.Contains(this))
			DisableAttacksRequesters.Remove(this);
		else
			DisableAttacksRequesters.Add(this);
	}

	UFUNCTION(DevFunction)
	private void TestMovement()
	{
		bDebuggingMovement = !bDebuggingMovement;
	}

	UFUNCTION(DevFunction)
	private void TestBreakEye()
	{
		{
			float Damage = HealthComp.CurrentHealth - Settings.DamageRequiredToBreakEye;
			HealthComp.TakeDamage(Damage, EDamageType::Default, this);
			bRecentlyGotDetonated = true;
			ChangePhase(ESkylineBallBossPhase::TopMioOnEyeBroken);
			BreakEye(true);
		}
	}
#endif
};