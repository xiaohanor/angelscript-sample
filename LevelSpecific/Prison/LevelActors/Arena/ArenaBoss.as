enum EArenaBossState
{
	Idle,
	Bombs,
	Disc,
	FlameThrower,
	RocketPunch,
	PlatformAttack,
	Smash,
	FacePunch,
	HandRemoved,
	ArmSmash,
	BatBomb,
	ArmThrow,
	ThrusterBlast,
	LaserEyes,
	HeadHack
}

event void FArenaBossEvent();
event void FArenaBossFacePunchEvent(bool bRightSide, bool bFinalPunch);
event void FArenaBossStateEnteredEvent(EArenaBossState State);
event void FArenaBossStateFinishedEvent(EArenaBossState State);

UCLASS(Abstract)
class AArenaBoss : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHandDeform")
	USceneComponent RightMagneticRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftHandDeform")
	USceneComponent LeftMagneticRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHandDeform")
	UNiagaraComponent HandThrusterEffectComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHandDeform")
	USceneComponent RightHackableRoot;

	UPROPERTY(DefaultComponent, Attach = RightHackableRoot)
	URemoteHackingResponseComponent HackableComp;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseAudioComponent HackableAudioComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftHandDeform")
	USceneComponent LeftHackableRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent HackedPunchPoiComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent HeadHackableRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent HeadMagneticRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHandDeform")
	USceneComponent RightPanelRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftHandDeform")
	USceneComponent LeftPanelRoot;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHandDeform")
	UBoxComponent RightHandCollision;
	default RightHandCollision.RelativeLocation = FVector(0.0, 0.0, 220.0);
	default RightHandCollision.BoxExtent = FVector(220.0, 300.0, 400.0);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftHandDeform")
	UBoxComponent LeftHandCollision;
	default LeftHandCollision.RelativeLocation = FVector(0.0, 0.0, 220.0);
	default LeftHandCollision.BoxExtent = FVector(220.0, 300.0, 400.0);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHandDeform")
	USceneComponent RocketPunchVisualizerComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UHazeTEMPCableComponent LeftCable;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UHazeTEMPCableComponent RightCable;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent HackSyncedComp;
	default HackSyncedComp.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMoveComp;

	EArenaBossState CurrentState;

	FArenaBossAnimationData AnimationData;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AArenaBomb> BombClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AArenaBossDiscAttack> DiscClass;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveMaterial;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FlyDownSpline;

	UPROPERTY(EditInstanceOnly)
	TArray<AArenaPlatform> BreakablePlatforms;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> BombPassiveCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> FlameThrowerCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LightCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MediumCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HeavyCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LightForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect MediumForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HeavyForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface SmashShadowMaterial;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> TelegraphDecalClass;

	UPROPERTY(EditDefaultsOnly)
	FText MagnetTutorialText;

	UPROPERTY(EditDefaultsOnly)
	FText HackTutorialText;

	UPROPERTY(EditDefaultsOnly)
	FText HackPunchChargeTutorialText;

	UPROPERTY(EditDefaultsOnly)
	FText HackPunchReleaseTutorialText;

	UPROPERTY(EditInstanceOnly)
	AActor LaunchPlayerToPlatformTarget;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBarWidget;

	UPROPERTY(EditDefaultsOnly)
	FText HealthBarText;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AArenaBossBatBomb> BatBombClass;

	UPROPERTY(EditDefaultsOnly)
	TArray<EArenaBossState> AttackSequence;
	bool bAttackSequenceActive = false;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ImpactDeathEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> ImpactDamageEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> FlameThrowerDeathEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ThrusterDeathEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> ThrusterDamageEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> LaserDeathEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> LaserDamageEffect;

	UPROPERTY()
	FArenaBossStateEnteredEvent OnStateEntered;

	UPROPERTY()
	FArenaBossStateFinishedEvent OnStateEnded;

	UPROPERTY()
	FArenaBossEvent OnAttackSequenceCompleted;

	UPROPERTY()
	FArenaBossFacePunchEvent OnFacePunched;

	UPROPERTY()
	FArenaBossEvent OnPlatformAttackStarted;

	UPROPERTY()
	FArenaBossEvent OnPlatformAttackEnded;

	UPROPERTY()
	FArenaBossEvent OnFinalMagnetPunch;

	UPROPERTY()
	FArenaBossEvent OnFinalRightPunch;

	UPROPERTY()
	FArenaBossEvent OnFinalLeftPunch;

	UPROPERTY()
	FArenaBossEvent OnHeadLaunched;

	UPROPERTY(EditInstanceOnly)
	AArenaBossArm ArmActor;

	UPROPERTY(EditInstanceOnly)
	AArenaBossHead HeadActor;

	UPROPERTY(EditInstanceOnly)
	AActor BatBombTargetPoint;

	UPROPERTY(EditInstanceOnly)
	ASplineActor LaserEyesMoveSpline;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat LaserEyesPlayRateCurve;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent LaserEye1;
	
	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent LaserEye2;

	int LaserEyesSpins = 0;

	FVector DefaultLocation;
	FRotator DefaultRotation;

	bool bRightHandRemoved = false;
	bool bLeftHandRemoved = false;

	/**
	 * This represent the 'hype' of the crowd watching the boss fight.
	 * 
	 * (cosmetic value that doesn't affect gameplay)
	 * 
	 * We have it here since most events seem to be pushed to the boss effect event handlers.
	 * There should be an EBP on the boss that manages this value. The arenacrowd actor will
	 * then read this and act accordingly.
	 */
	UPROPERTY(NotVisible)
	float CrowdIntensity = 0.5;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultLocation = ActorLocation;
		DefaultRotation = ActorRotation;

		ArmActor.AttachToComponent(Mesh, n"RightArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

		HeadActor.SetActorEnableCollision(false);
		HeadActor.AttachToComponent(Mesh, n"Head", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		HackableComp.OnLaunchStarted.AddUFunction(this, n"HackLaunchStarted");

		HackSyncedComp.OverrideControlSide(Game::Mio);

		LeftCable.SetAttachEndTo(HeadActor, n"LeftCableAttachComp");
		RightCable.SetAttachEndTo(HeadActor, n"RightCableAttachComp");
	}

	UFUNCTION()
	private void HackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		if (bRightHandRemoved)
			LeftHandCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		else
			RightHandCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(DevFunction)
	void StartDefaultAttackSequence()
	{
		bAttackSequenceActive = true;
	}

	UFUNCTION()
	void StartCustomAttackSequence(TArray<EArenaBossState> NewSequence)
	{
		AttackSequence = NewSequence;
		bAttackSequenceActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAttackSequenceActive)
		{
			if (AttackSequence.Num() > 0)
			{
				if (CurrentState == EArenaBossState::Idle)
				{
					// if (TargetIdleTime != 0.0)
					// {
					// 	CurrentIdleTime += DeltaTime;
					// 	if (CurrentIdleTime >= TargetIdleTime)
					// 		TriggerQueuedAttack();
					// }
					// else
					// {
					// 	TriggerQueuedAttack();
					// }

					TriggerQueuedAttack();
				}
			}
			else
			{
				bAttackSequenceActive = false;
				OnAttackSequenceCompleted.Broadcast();
			}
		}

		FVector LocalTranslation = ActorTransform.TransformVector(VelocityTrackerComp.GetLastFrameDeltaTranslation()).GetSafeNormal();
		FVector2D Local2D = FVector2D(-LocalTranslation.Y, LocalTranslation.X);
		AnimationData.MoveDirection = Local2D;
	}

	void TriggerQueuedAttack()
	{
		// TargetIdleTime = 0.0;
		ActivateState(AttackSequence[0]);
		AttackSequence.RemoveAt(0);
	}

	UFUNCTION()
	void ActivateState(EArenaBossState State)
	{
		CurrentState = State;
	}

	UFUNCTION()
	void ResetState()
	{
		CurrentState = EArenaBossState::Idle;
	}

	UFUNCTION()
	void SpreadPlatforms()
	{
		TListedActors<AArenaPlatform> Platforms;
		for (AArenaPlatform Platform : Platforms)
			Platform.SpreadPlatform(true);
	}

	UFUNCTION()
	void ResetPlatforms()
	{
		TListedActors<AArenaPlatform> Platforms;
		for (AArenaPlatform Platform : Platforms)
			Platform.ResetPlatform();
	}

	UFUNCTION()
	void LaunchPlayerBackToPlatform()
	{
		FPlayerLaunchToParameters LaunchToParams;
		LaunchToParams.Duration = 2.0;
		LaunchToParams.LaunchToLocation = LaunchPlayerToPlatformTarget.ActorLocation;
		LaunchToParams.bRotate = false;
		Game::Mio.LaunchPlayerTo(this, LaunchToParams);
	}

	UFUNCTION()
	void ShowHealthBar(float Health = 18.0)
	{
		if (HealthBarWidget != nullptr)
			return;

		HealthBarWidget = Widget::AddFullscreenWidget(HealthBarClass);
		HealthBarWidget.InitBossHealthBar(HealthBarText, 18.0, 3);
		HealthBarWidget.SnapHealthTo(Health);
	}

	UFUNCTION()
	void RemoveHealthBar()
	{
		if (HealthBarWidget == nullptr)
			return;

		Widget::RemoveFullscreenWidget(HealthBarWidget);
		HealthBarWidget = nullptr;
	}

	void TakeDamage(float Damage)
	{
		if (HealthBarWidget != nullptr)
			HealthBarWidget.TakeDamage(Damage);
	}

	UFUNCTION(DevFunction)
	void SetRightHandHidden()
	{
		bRightHandRemoved = true;
		AnimationData.bRightHandRemoved = true;
		HideRightHand();
	}

	UFUNCTION()
	void HideRightHand()
	{
		Mesh.HideBoneByName(n"RightHand", EPhysBodyOp::PBO_None);
		RightMagneticRoot.SetHiddenInGame(true, true);
		RightPanelRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION(DevFunction)
	void HideRightArm(bool bShowArmActor, bool bHideShoulderPad)
	{
		SetRightHandHidden();
		Mesh.HideBoneByName(n"RightArm", EPhysBodyOp::PBO_None);
		ArmActor.SetActorHiddenInGame(!bShowArmActor);

		if (bHideShoulderPad)
			Mesh.HideBoneByName(n"RightShoulderPad", EPhysBodyOp::PBO_None);
	}

	UFUNCTION(DevFunction)
	void SetLeftHandHidden()
	{
		bLeftHandRemoved = true;
		HideLeftHand();
	}

	UFUNCTION()
	void HideLeftHand()
	{
		Mesh.HideBoneByName(n"LeftHand", EPhysBodyOp::PBO_None);
		LeftMagneticRoot.SetHiddenInGame(true, true);
		LeftPanelRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	void HideHead()
	{
		Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
	}

	UFUNCTION(DevFunction)
	void RipOffArm()
	{
		ActivateState(EArenaBossState::ArmSmash);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateLaserEyes() {}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateLaserEyes() {}

	UFUNCTION(BlueprintEvent)
	void BP_StartOverHeating() {}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateCables() {}

	UFUNCTION(BlueprintEvent)
	void BP_SnapCables() {}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateHackableEffect(bool bLeft) {}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateHackableHeadEffect() {}

	UFUNCTION(BlueprintEvent)
	void BP_RevealHeadHackablePanel() {}

	UFUNCTION(BlueprintEvent)
	void BP_RocketPunchTargeting () {}

	UFUNCTION(BlueprintEvent)
	void BP_RocketPunchLaunched () {}

	UFUNCTION(BlueprintEvent)
	void BP_HandHacked(bool bLeft) {}

	UFUNCTION(BlueprintEvent)
	void BP_HackPunchStarted(bool bLeft) {}

	UFUNCTION(BlueprintEvent)
	void BP_HackPunchImpact(bool bLeft) {}

	UFUNCTION(BlueprintEvent)
	void BP_HandUnhacked(bool bLeft) {}

	UFUNCTION(BlueprintPure)
	FHitResult GetLaserHitResult(UNiagaraComponent LaserComp)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(HeadActor);
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(LaserComp.WorldLocation, LaserComp.WorldLocation + LaserComp.ForwardVector * 15000.0);
		return Hit;
	}

	void EnableHandCollision()
	{
		if (bRightHandRemoved)
			LeftHandCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		else
			RightHandCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	void DisableHandCollision()
	{
		if (bRightHandRemoved)
			LeftHandCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		else
			RightHandCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	void DisableBothHandCollisions()
	{
		LeftHandCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		RightHandCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintPure)
	bool IsRightHandRemoved()
	{
		return bRightHandRemoved;
	}

	UFUNCTION(DevFunction)
	void ToggleHealthBar()
	{
		if (HealthBarWidget == nullptr)
			ShowHealthBar();
		else
			RemoveHealthBar();
	}

	UFUNCTION(DevFunction)
	void ToggleRocketPunch()
	{
		if (CurrentState == EArenaBossState::RocketPunch)
			ResetState();
		else
			ActivateState(EArenaBossState::RocketPunch);
	}

	UFUNCTION(DevFunction)
	void ToggleBombs()
	{
		if (CurrentState == EArenaBossState::Bombs)
			ResetState();
		else
			ActivateState(EArenaBossState::Bombs);
	}

	UFUNCTION(DevFunction)
	void ToggleFlameThrower()
	{
		if (CurrentState == EArenaBossState::FlameThrower)
			ResetState();
		else
			ActivateState(EArenaBossState::FlameThrower);
	}

	UFUNCTION(DevFunction)
	void ToggleSmash()
	{
		if (CurrentState == EArenaBossState::Smash)
			ResetState();
		else
			ActivateState(EArenaBossState::Smash);
	}

	UFUNCTION(DevFunction)
	void ToggleDisc()
	{
		if (CurrentState == EArenaBossState::Disc)
			ResetState();
		else
			ActivateState(EArenaBossState::Disc);
	}

	UFUNCTION(DevFunction)
	void TogglePlatformAttack()
	{
		if (CurrentState == EArenaBossState::PlatformAttack)
			ResetState();
		else
			ActivateState(EArenaBossState::PlatformAttack);
	}

	UFUNCTION(DevFunction)
	void ToggleThrusterBlast()
	{
		if (CurrentState == EArenaBossState::ThrusterBlast)
			ResetState();
		else
			ActivateState(EArenaBossState::ThrusterBlast);
	}

	UFUNCTION(DevFunction)
	void ToggleLaserEyes()
	{
		if (CurrentState == EArenaBossState::LaserEyes)
			ResetState();
		else
			ActivateState(EArenaBossState::LaserEyes);
	}

	UFUNCTION(DevFunction)
	void TriggerFacePunch()
	{
		if (CurrentState == EArenaBossState::FacePunch)
			ResetState();
		else
			ActivateState(EArenaBossState::FacePunch);
	}

	UFUNCTION(DevFunction)
	void TriggerHackableState()
	{
		if (CurrentState == EArenaBossState::HandRemoved)
			ResetState();
		else
		{
			ActivateState(EArenaBossState::HandRemoved);
			SetActorLocation(DefaultLocation + (ActorForwardVector * 1500.0));
		}
	}
}