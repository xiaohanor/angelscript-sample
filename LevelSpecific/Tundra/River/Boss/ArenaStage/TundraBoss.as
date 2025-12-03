event void FTundraBossEvent();
event void FOnIceKingHitBySphere(int NumberOfTimesHit);

class ATundraBoss : AHazeCharacter
{
	//Default Components
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "OrbSocket")
	UNiagaraComponent OrbImpactFX;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Head")
	USceneComponent FurBallSpawnLoc;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "OrbSocket")
	USceneComponent PunchTutorialLoc;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossSpawnCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossDefeatedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossSpawnLastPhaseCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossReturnAfterFirstSphereHitCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossHiddenCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossTakePunchDamageCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossTakeSphereDamageCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossGrabbedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossBreakFreeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossBreakFreeFromStruggleCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossGetBackUpFromSphereCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossWaitCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossWaitUnlimitedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossJumpToLocationCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossClawAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossRingOfIceSpikesCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossChargeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossFallingIceSpikeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossFallingRedIceCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossBreakingIceCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossFurBallCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossFurBallUnlimitedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossStopFurballCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossWhirlwindCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossStopFallingIceSpikeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossStopRedIceCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UTundraBossFinalPunchCapability);

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UTundraTreeGuardianRangedInteractionTargetableComponent RangedTreeInteractionTargetComp;
	default RangedTreeInteractionTargetComp.InteractionType = ETundraTreeGuardianRangedInteractionType::LifeGive;
	default RangedTreeInteractionTargetComp.bBlockCancel = true;
	default RangedTreeInteractionTargetComp.AutoAimMaxAngle = 20;
	default RangedTreeInteractionTargetComp.TargetShape.Type = EHazeShapeType::Sphere;
	default RangedTreeInteractionTargetComp.TargetShape.SphereRadius = 300;
	default RangedTreeInteractionTargetComp.bIceKingHoldDownBlockDeath = true;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Spine2")
	UBoxComponent GrabbedKillCollision;
	default GrabbedKillCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
	default GrabbedKillCollision.RelativeLocation = FVector(-408, 14.6, 192.7);
	default GrabbedKillCollision.BoxExtent = FVector(115, 244, 883);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "OrbSocket")
	UTundraTreeGuardianRangedShootTargetable LaunchSphereHitComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "OrbSocket")
	USphereComponent LaunchSphereHitCollision;
	default LaunchSphereHitCollision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default LaunchSphereHitCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MovementAudioComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent CloseAttackVolume;
	default CloseAttackVolume.CollisionProfileName = n"TriggerOnlyPlayer";
	default CloseAttackVolume.SphereRadius = 1400;
	default CloseAttackVolume.SetRelativeLocation(FVector(700, 0, -500));

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent HazeVoxCharacterTemplateComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	/* --Anim Instance-- */
	UTundraBossAnimInstance AnimInstance;

	/* --Material Transform Reference-- */
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	AMaterialTransform MaterialTransformReference;

	
	/* --Health Bar Settings-- */
	UPROPERTY()
	UBasicAIHealthBarSettings HealthBarSetting;

	/* --State Manager-- */
	UPROPERTY()
	ETundraBossStates State = ETundraBossStates::NotSpawned;
	UPROPERTY(EditInstanceOnly)
	TMap<ETundraBossPhases, FTundraBossAttackQueueStruct> AttackPhases;
	ETundraBossPhases CurrentPhase = ETundraBossPhases::None;
	FTundraBossAttackQueueStruct CurrentPhaseAttackStruct;
	int QueueIndex = 0;

	/* --Events-- */
	FTundraBossEvent SpawnClawAttackRightPaw;
	FTundraBossEvent SpawnClawAttackLeftPaw;
	FTundraBossEvent CloseAttack;
	FTundraBossEvent BreakIce;
	FTundraBossEvent SpawnRingOfIce;
	FTundraBossEvent FurBall01;
	FTundraBossEvent FurBall02;
	FTundraBossEvent OnChargeKillCollisionActivate;
	FTundraBossEvent OnFinalPunchingThisFrame;
	FTundraBossEvent OnLastFinalPunch;
	UPROPERTY()
	FTundraBossEvent JumpedToNewLocationInLastPhase;
	UPROPERTY()
	FTundraBossEvent OnFinalPunchDealt;
	UPROPERTY()
	FTundraBossEvent StartTreeGrabSeq;
	UPROPERTY()
	FTundraBossEvent StopTreeGrabSeq;
	UPROPERTY()
	FTundraBossEvent OnHitBySphere;
	UPROPERTY()
	FTundraBossEvent EnterPhaseOne();
	UPROPERTY()
	FTundraBossEvent EnterPhaseTwo();
	UPROPERTY()
	FTundraBossEvent BossFightFinished();
	UPROPERTY()
	FTundraBossEvent TriggerBossDefeatedCutscene();
	UPROPERTY()
	FTundraBossEvent OnPlayBreakIceSequence();
	UPROPERTY()
	FTundraBossEvent OnPlayHitByFirstSphereSequence();
	UPROPERTY()
	FTundraBossEvent OnGotBackUpFromSphereHit();

	UPROPERTY()
	FTundraBossEvent OnLastPunchStarted;
	UPROPERTY()
	FTundraBossEvent OnLastPunchSlomoStarted;

	/* --Actor References-- */
	UPROPERTY(EditInstanceOnly, Category = "Init")
	TArray<ATundraBossRingOfIceSpikesActor> RingOfIceSpikeActors;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeTargetPoint IceHeight;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeActor MonkeyPunchFocusActor;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeCameraActor MonkeyPunchCamera;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeCameraActor SecondPunchCamera;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeCameraActor FinalPunchCamera01;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeCameraActor FinalPunchCamera02;
	UPROPERTY(EditInstanceOnly, Category = "Init")
	AHazeSkeletalMeshActor LastPhasePositionActor;
	UPROPERTY(EditInstanceOnly, Category = "Phase02Platforms")
	ATundraBossBossPlatform Phase02FrontPlatform;
	UPROPERTY(EditInstanceOnly, Category = "Phase02Platforms")
	ATundraBossBossPlatform Phase02LeftPlatform;
	UPROPERTY(EditInstanceOnly, Category = "Phase02Platforms")
	ATundraBossBossPlatform Phase02RightPlatform;
	UPROPERTY(EditInstanceOnly, Category = "Phase02Platforms")
	TArray<ATundraBossBossPlatform> Phase02Platforms;
	UPROPERTY(EditInstanceOnly, Category = "Phase03Platforms")
	ATundraBossBossPlatform Phase03LeftPlatform;
	UPROPERTY(EditInstanceOnly, Category = "Phase03Platforms")
	ATundraBossBossPlatform Phase03RightPlatform;
	UPROPERTY(EditInstanceOnly, Category = "Phase03Platforms")
	TArray<ATundraBossBossPlatform> Phase03Platforms;
	UPROPERTY(EditInstanceOnly, Category = "TreeGrab")
	ATundraBossTreeGrabSequenceScrubActor TreeGrabSequenceScrubActor;
	UPROPERTY(EditInstanceOnly, Category = "ClawAttack")
	ATundraBossClawAttackActorNew ClawAttackNewRight;
	UPROPERTY(EditInstanceOnly, Category = "ClawAttack")
	ATundraBossClawAttackActorNew ClawAttackNewLeft;
	UPROPERTY(EditInstanceOnly, Category = "IcicleAttack")
	ATundraBossFallingIciclesManager FallingIciclesManager;
	UPROPERTY(EditInstanceOnly, Category = "RedIce")
	ATundraBossRedIceManager RedIceManager;
	UPROPERTY(EditInstanceOnly, Category = "ChargeAttack")
	ATundraBossFallingIceBlocksManager FallingIceBlocksManager;
	UPROPERTY(EditInstanceOnly, Category = "ChargeAttack")
	AHazeActor ChargeRoot;
	UPROPERTY(EditInstanceOnly, Category = "ChargeAttack")
	AHazeTargetPoint FrontTargetPoint;
	UPROPERTY(EditInstanceOnly, Category = "ChargeAttack")
	AHazeTargetPoint LeftTargetPoint;
	UPROPERTY(EditInstanceOnly, Category = "ChargeAttack")
	AHazeTargetPoint RightTargetPoint;
	UPROPERTY(EditInstanceOnly, Category = "ChargeAttack")
	ATundraBossChargeKillCollision ChargeKillCollisionActor;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	ATundraBossHomingIceChunk MioIceChunk;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	ATundraBossHomingIceChunk ZoeIceChunk;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	ATundraBossCrackingIce CrackingIce;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	ATundraBossWhirlwindActor WhirlwindActor;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	ATundraBossRaisingPlatform RaisingPlatform01;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	ATundraBossRaisingPlatform RaisingPlatform02;
	UPROPERTY(EditInstanceOnly, Category = "LastPhase")
	AHazeLevelSequenceActor HitByFirstSphereSequencer;
	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> FinalPunchCamShake;
	UPROPERTY(EditInstanceOnly)
	ATundraSnowMonkeyIceKingBossPunchInteractionActor ConnectedPunchInteractionActorPhase02;
	UPROPERTY(EditInstanceOnly)
	ATundraSnowMonkeyIceKingBossPunchInteractionActor ConnectedPunchInteractionActorPhase03;
	UPROPERTY(EditInstanceOnly)
	ATundraSnowMonkeyIceKingBossPunchInteractionActor ConnectedFinalPunchInteractionActor;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset  ZoeKeepIceKingDownCamSettings;
		
	UPROPERTY()
	TSubclassOf<UDeathEffect> CloseAttackDeathEffect;

	ETundraBossLocation CurrentBossLocation = ETundraBossLocation::Front;
	bool bHasTakenDamageInCurrentState = false;
	bool bSkipBreakIce = false;
	int TimesRecievedPunchDamageInPhase03 = 0;
	bool bHasAttackedPhase02B = false;
	bool bStopFurballFromSpawning = false;
	

	float CanProgressAfterFirstFurballTimer;
	float CanProgressAfterFirstFurballTimerDuration;
	bool bShouldTickProgressAfterFirstFurballTimer = false;
	bool bProgressWhenFurballTimerIsFinished = false;

	UPROPERTY()
	bool bBlockTauntPlayerDeaths = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetZoe());

		if(HasControl())
			GoToPhase(ETundraBossPhases::None);

		AnimInstance = Cast<UTundraBossAnimInstance>(Mesh.AnimInstance);

		//Attach components to animation
		MonkeyPunchFocusActor.AttachToComponent(Mesh, n"OrbSocket", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		RangedTreeInteractionTargetComp.AttachToComponent(Mesh, n"TreeInteractionSocket", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		//Deactivate components
		RangedTreeInteractionTargetComp.Disable(this);

		//Bind Events
		LaunchSphereHitComp.OnHit.AddUFunction(this, n"HitByLaunchSphere");
		CrackingIce.OnCrackingIceExploded.AddUFunction(this, n"OnCrackingIceExploded");
		CrackingIce.OnCrackingIceCracked.AddUFunction(this, n"OnCrackingIceCracked");
		FurBall01.AddUFunction(this, n"OnSpawnFurBall01");
		FurBall02.AddUFunction(this, n"OnSpawnFurBall02");
		OnChargeKillCollisionActivate.AddUFunction(this, n"OnActivateChargeKillCollision");
		GrabbedKillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnGrabbedKillCollisionOverlap");

		//Bind Punch Enter
		SetPunchInteractionPhase02Active(false);
		SetPunchInteractionPhase03Active(false);
		SetFinalPunchInteractionActive(false);
		UTundraPlayerSnowMonkeyIceKingBossPunchComponent PunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::GetMio());
		PunchComp.OnEntered.AddUFunction(this, n"OnMonkeyPunchEntered");

		Phase02Platforms.Add(Phase02FrontPlatform);
		Phase02Platforms.Add(Phase02LeftPlatform);
		Phase02Platforms.Add(Phase02RightPlatform);

		//Phase03 doens't have a front platform
		Phase03Platforms.Add(Phase03LeftPlatform);
		Phase03Platforms.Add(Phase03RightPlatform);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			return;

		if(bShouldTickProgressAfterFirstFurballTimer)
		{
			CanProgressAfterFirstFurballTimer += DeltaSeconds;
			if(CanProgressAfterFirstFurballTimer >= CanProgressAfterFirstFurballTimerDuration)
			{
				bShouldTickProgressAfterFirstFurballTimer = false;
				
				if(bProgressWhenFurballTimerIsFinished)
					ProgressQueue();
			}
		}
	}

	UFUNCTION()
	private void OnGrabbedKillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                           UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                           bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.KillPlayer();
	}

	UFUNCTION()
	void SetBossInHiddenState()
	{
		if(HasControl())
		{
			CrumbPushAttack(ETundraBossStates::Hidden);
		}
	}

	UFUNCTION()
	void OnMonkeyPunchEntered(ETundraPlayerSnowMonkeyIceKingBossPunchType PunchType)
	{
		if(!HasControl())
			return; 

		if(PunchType != ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch)
		{
			// Change GroundSlam to Punch
			CrumbTakeDamage(ETundraBossDamageSource::GroundSlam);
		}
		else
		{
			//We're disregarding the queue here and setting the State directly, since this is that last thing that happens in the Boss Fight.
			GoToState(ETundraBossStates::FinalPunch, -1);
		}
	}

	UFUNCTION()
	void HitByLaunchSphere()
	{
		if(!HasControl())
			return;
		
		if(State != ETundraBossStates::JumpToNextLocation)
			CrumbTakeDamage(ETundraBossDamageSource::SphereLauncher);		
	}

	void IceKingHitBySphere()
	{
		//Move logic to function above?
		OnHitBySphere.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	void CrumbTakeDamage(ETundraBossDamageSource InDamageSource)
	{
		if(InDamageSource == ETundraBossDamageSource::GroundSlam)
			PushAttack(ETundraBossStates::PunchDamage);
		else
			PushAttack(ETundraBossStates::SphereDamage);
	}

	UFUNCTION()
	void RequestAnimation(ETundraBossAttackAnim RequestedAnim, bool bInstantSpawn = false)
	{
		AnimInstance.RequestedAnimation = RequestedAnim;
		AnimInstance.bInstantSpawn = bInstantSpawn;
	}
	
	UFUNCTION()
	void SetAmountOfTimesRecievedPunchDamageInPhase03(int Hits)
	{
		if(!HasControl())
			return;

		TimesRecievedPunchDamageInPhase03 = Hits;
	}

	UFUNCTION()
	void ProgressQueue()
	{
		if(!HasControl())
			return;
		
		if(CurrentPhaseAttackStruct.Queue.IsValidIndex(QueueIndex + 1))
		{
			QueueIndex++;
			GoToState(CurrentPhaseAttackStruct.Queue[QueueIndex], QueueIndex);
		}
		else
		{
			GoToPhase(CurrentPhaseAttackStruct.NextPhaseIfNotDamaged);
		}
	}

	UFUNCTION()
	void ProgressQueueAfterFirstFurball()
	{
		if(!HasControl())
			return;

		if(CanProgressAfterFirstFurballTimer < CanProgressAfterFirstFurballTimerDuration)
		{
			bProgressWhenFurballTimerIsFinished = true;
			bStopFurballFromSpawning = true;
		}
		else
		{
			ProgressQueue();
		}
	}

	UFUNCTION()
	void StartProgressAfterFirstFurballTimer(float TimerDuration)
	{
		if(!HasControl())
			return;

		CanProgressAfterFirstFurballTimer = 0;
		CanProgressAfterFirstFurballTimerDuration = TimerDuration;
		bProgressWhenFurballTimerIsFinished = false;
		bShouldTickProgressAfterFirstFurballTimer = true;
	}
	
	// Used for VO so that we can trigger an attack specific VO before it starts. 
	ETundraBossStates GetNextState()
	{
		if(CurrentPhaseAttackStruct.Queue.IsValidIndex(QueueIndex+1))
			return CurrentPhaseAttackStruct.Queue[QueueIndex+1];
		else
		{
			FTundraBossAttackQueueStruct NextPhase;
			if (AttackPhases.Find(CurrentPhaseAttackStruct.NextPhaseIfNotDamaged, NextPhase))
				return NextPhase.Queue[0];
			else
				return ETundraBossStates::None;
		}
	}

	void GoToState(ETundraBossStates InState, int NewQueueIndex)
	{
		QueueIndex = NewQueueIndex;
		State = InState;
	}

	UFUNCTION()
	void CapabilityStopped(ETundraBossStates InState)
	{
		if(!HasControl())
			return;

		// GetBackUpAfterSphere only happens in Phase03 and if Mio didn't punch Ice King in time. Go directly to NextPhaseIfNotDamaged.
		if(InState == ETundraBossStates::GetBackUpAfterSphere)
		{
			GoToPhase(CurrentPhaseAttackStruct.NextPhaseIfNotDamaged);
			return;
		}

		if(State == InState && InState != ETundraBossStates::SphereDamage && InState != ETundraBossStates::PunchDamage)
		{
			ProgressQueue();
		}
		else if(InState == ETundraBossStates::SphereDamage || InState == ETundraBossStates::PunchDamage)
		{
			bHasTakenDamageInCurrentState = false;
			GoToPhase(CurrentPhaseAttackStruct.NextPhaseIfDamaged);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPushAttack(ETundraBossStates InAttack)
	{
		State = InAttack;
	}

	void PushAttack(ETundraBossStates InAttack)
	{
		State = InAttack;
	}

	void GoToPhase(ETundraBossPhases InPhase)
	{		
		if(!HasControl())
			return;

		CurrentPhase = InPhase;
		if(CurrentPhase == ETundraBossPhases::Phase_1A)
		{
			//Note! Phase02 in the entire IceKing fight.
			CrumbEnterPhase01();
		}
		else if(CurrentPhase == ETundraBossPhases::Phase_2A)
		{
			//Note! Phase03 in the entire IceKing fight.
			CrumbEnterPhase02();
		}

		if(CurrentPhase != ETundraBossPhases::Dead)
		{
			CurrentPhaseAttackStruct = AttackPhases.FindOrAdd(InPhase);
			CrumbActivateRespawnPoint(CurrentPhaseAttackStruct.RespawnPointInPhase);
			QueueIndex = -1;
			ProgressQueue();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateRespawnPoint(ATundraShapeshiftingRespawnPoint InRespawnPoint)
	{
		if(InRespawnPoint != nullptr)
		{
			Game::GetMio().SetStickyRespawnPoint(InRespawnPoint);
			Game::GetZoe().SetStickyRespawnPoint(InRespawnPoint);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbEnterPhase01()
	{
		//Note! Phase02 in the entire IceKing fight.
		EnterPhaseOne.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	void CrumbEnterPhase02()
	{
		//Note! Phase03 in the entire IceKing fight.
		EnterPhaseTwo.Broadcast();
	}

	UFUNCTION()
	void SpawnPhase03FirstPart(bool bInstantSpawn, bool bWithCutscene = true)
	{
		if(!HasControl())
			return;

		if(bWithCutscene)
		{
			CrumbSpawnPhase03(ETundraBossPhases::Phase_2A, ETundraBossStates::SpawnLastPhase, bInstantSpawn);		
		}
		else
		{
			CrumbSpawnPhase03(ETundraBossPhases::Phase_2B, ETundraBossStates::SpawnLastPhase, bInstantSpawn);
		}
	}

	UFUNCTION()
	void SpawnPhase03LastPart()
	{
		if(!HasControl())
			return;
		
		CrumbSpawnPhase03(ETundraBossPhases::Phase_2C, ETundraBossStates::SpawnLastPhase, true);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnPhase03(ETundraBossPhases PhaseToPush, ETundraBossStates StateToPush, bool bInstantSpawn)
	{
		if(PhaseToPush == ETundraBossPhases::Phase_2A)
			bSkipBreakIce = true;

		GoToPhase(PhaseToPush);
		
		if(bInstantSpawn)
		{
			PushAttack(StateToPush);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbUpdateTundraBossHealthSettings(float NewHealth)
	{
		HealthComponent.SetCurrentHealth(NewHealth);
		ApplySettings(HealthBarSetting, this, EHazeSettingsPriority::Override);
		HealthBarComponent.UpdateHealthBarSettings();
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateGrabbedKillCollision(bool bShouldBeActivated)
	{
		ECollisionEnabled Collision = bShouldBeActivated ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision;
		GrabbedKillCollision.CollisionEnabled = Collision;
	}

	void ActivateGrabbedKillCollision(bool bShouldBeActivated)
	{
		ECollisionEnabled Collision = bShouldBeActivated ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision;
		GrabbedKillCollision.CollisionEnabled = Collision;
	}

	void SetIceKingCollisionEnabled(bool bEnabled)
	{
		ECollisionEnabled Collision = bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		Mesh.SetCollisionEnabled(Collision);
	}

	//Called from AnimNotify - Activates a static kill collision where the Ice King lands during the charge attack
	UFUNCTION()
	private void OnActivateChargeKillCollision()
	{
		ChargeKillCollisionActor.ActivateChargeKillCollisionForDuration(0.75);
	}

	void SetPunchInteractionPhase02Active(bool bNewActive)
	{
		if (bNewActive)
			ConnectedPunchInteractionActorPhase02.Enable(this);
		else
			ConnectedPunchInteractionActorPhase02.Disable(this);
	}

	void SetPunchInteractionPhase03Active(bool bNewActive)
	{
		if (bNewActive)
			ConnectedPunchInteractionActorPhase03.Enable(this);
		else
			ConnectedPunchInteractionActorPhase03.Disable(this);
	}

	void SetFinalPunchInteractionActive(bool bNewActive)
	{
		if(bNewActive)
			ConnectedFinalPunchInteractionActor.Enable(this);
		else
			ConnectedFinalPunchInteractionActor.Disable(this);
	}

	void SetPunchingThisFrame(bool Punch, ETundraPlayerSnowMonkeyIceKingBossPunchType PunchType, int AmountOfPunchesPerformed)
	{
		AnimInstance.bPunchingThisFrame = Punch;
		AnimInstance.bFinalPunchThisFrame = Punch;

		if(Punch)
			UTundraBoss_EffectHandler::Trigger_OnMonkeyPunch(this);

		if(AmountOfPunchesPerformed != -1)
		{
			AnimInstance.AmountOfPunches = AmountOfPunchesPerformed;
			PrintToScreen("AmountOfPunchesPerformed: " + AmountOfPunchesPerformed, 2);
		}
		
		if(Punch && PunchType == ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch)
		{
			//This is used in TundraBossFinalPunchCapability
			OnFinalPunchingThisFrame.Broadcast();
		}
	}

	void SetLastFinalPunchThisFrame(bool Punch)
	{
		AnimInstance.bShouldPlayLastFinalPunch = Punch;
		OnLastFinalPunch.Broadcast();

		if(Punch)
			UTundraBoss_EffectHandler::Trigger_OnMonkeyPunchFinal(this);
	}

	//FurBall events are being broadcast from TundraBossAnimNotifies
	UFUNCTION()
	private void OnSpawnFurBall01()
	{
		MioIceChunk.ActivateIceChunkFromIceKingAnimation(FurBallSpawnLoc.WorldLocation, ActorForwardVector);
	}
	
	//FurBall events are being broadcast from TundraBossAnimNotifies
	UFUNCTION()
	private void OnSpawnFurBall02()
	{
		ZoeIceChunk.ActivateIceChunkFromIceKingAnimation(FurBallSpawnLoc.WorldLocation, ActorForwardVector);
	}

	UFUNCTION()
	void CrackingIceFrozen()
	{
		UTundraBoss_EffectHandler::Trigger_OnCrackingIceFrozen(this);
	}

	UFUNCTION()
	private void OnCrackingIceCracked()
	{
		UTundraBoss_EffectHandler::Trigger_OnCrackingIceCracked(this);
	}

	UFUNCTION()
	private void OnCrackingIceExploded()
	{
		ProgressQueue();
		UTundraBoss_EffectHandler::Trigger_OnCrackingIceExploded(this);

		MioIceChunk.ExplodeFromIceExplosion();
		ZoeIceChunk.ExplodeFromIceExplosion();
	}

	void ActivateNextBossPlatform(ATundraBossBossPlatform PlatformToShow, bool bLastPhase)
	{
		if(PlatformToShow == nullptr && bLastPhase)
		{
			for(auto Platform : Phase03Platforms)
				Platform.HidePlatform();

			return;
		}

		TArray<ATundraBossBossPlatform> PlatformArray = bLastPhase ? Phase03Platforms : Phase02Platforms;	
		for(auto Platform : PlatformArray)
		{
			if (Platform == PlatformToShow)
				Platform.ShowPlatform();
			else
				Platform.HidePlatform();
		}
	}

	bool IsInLastPhase() const
	{
		if(CurrentPhase == ETundraBossPhases::Phase_1A || CurrentPhase == ETundraBossPhases::Phase_1A_Repeat
		|| CurrentPhase == ETundraBossPhases::Phase_1B || CurrentPhase == ETundraBossPhases::Phase_1B_Repeat 
		|| CurrentPhase == ETundraBossPhases::Phase_1C || CurrentPhase == ETundraBossPhases::Phase_1C_Repeat)
		{
			return false;
		}
		else
		{
			return true;
		}
	}

	ATundraBossBossPlatform GetTargetPhase02Platform(ETundraBossLocation NewTargetLocation)
	{
		switch(NewTargetLocation)
		{
			case ETundraBossLocation::Front:
				return Phase02FrontPlatform;

			case ETundraBossLocation::Left:
				return Phase02LeftPlatform;

			case ETundraBossLocation::Right:
				return Phase02RightPlatform;
		}
	}

	ATundraBossBossPlatform GetTargetPhase03Platform(ETundraBossLocation NewTargetLocation)
	{
		switch(NewTargetLocation)
		{
			case ETundraBossLocation::Front:
				return nullptr;

			case ETundraBossLocation::Left:
				return Phase03LeftPlatform;

			case ETundraBossLocation::Right:
				return Phase03RightPlatform;
		}
	}

	ETundraBossLocation SetTargetLocation() const
	{
		if(CurrentBossLocation == ETundraBossLocation::Front)
			return ETundraBossLocation::Left;
		else if(CurrentBossLocation == ETundraBossLocation::Left)
			return ETundraBossLocation::Right;
		else
			return ETundraBossLocation::Front;
	}

	//If the attack is the last one in the queue for this phase, the NextAttack will be "None". If the length of the current attack isn't determined by time (Other factors pushing the queue forward), CurrentAttackDuration will be -1. 
	void OnAttackEventHandler(float AttackDuration)
	{
		FTundraBossAttackData Data;
		Data.CurrentAttack = State;
		Data.CurrentAttackDuration = AttackDuration;
		
		if(CurrentPhaseAttackStruct.Queue.IsValidIndex(QueueIndex + 1))
			Data.NextAttack = CurrentPhaseAttackStruct.Queue[QueueIndex + 1];
		else
			Data.NextAttack = ETundraBossStates::None;
		
		UTundraBoss_EffectHandler::Trigger_OnAttack(this, Data);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FFGrabbed(){}

	UFUNCTION()
	void ClearPunchCameraViewSizeOverride()
	{
		UTundraBossHandlePlayerPunchViewComponent::GetOrCreate(this).ClearPunchCamViewSizeOverride();
	}
};

namespace TundraBossArena
{
	UFUNCTION()
	ATundraBoss GetTundraBoss()
	{
		return TListedActors<ATundraBoss>().GetSingle();
	}
};