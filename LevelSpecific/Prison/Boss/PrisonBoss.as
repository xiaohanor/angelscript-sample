enum EPrisonBossAttackType
{
	None,
	Spiral,
	WaveSlash,
	Clone,
	GroundTrail,
	HackableMagneticProjectile,
	DashSlash,
	GrabPlayer,
	Donut,
	GrabDebris,
	HorizontalSlash,
	MagneticSlam,
	PlatformDangerZone,
	ZigZag,
	Scissors,
}

event void FPrisonBossAttackCompletedEvent(EPrisonBossAttackType Attack);
event void FPrisonBossGrabbedPlayerEvent();
event void FPrisonBossHackedEvent();
event void FPrisonBossStunnedEvent();
event void FPrisonBossRecoveredFromStunEvent(bool bNaturally);
event void FPrisonBossAttackTriggeredEvent(EPrisonBossAttackType Attack);
event void FPrisonBossSequenceCompletedEvent();
event void FPrisonBossMagneticProjectileHitEvent();
event void FPrisonBossPlayerLostControlEvent();
event void FPrisonBossPhaseCompletedEvent();
event void FPrisonBossMagnetBlastedEvent();

UCLASS(Abstract)
class APrisonBoss : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	USceneComponent WeaponEndPointComp;

	UPROPERTY(DefaultComponent, Attach = WeaponEndPointComp)
	USceneComponent MagneticProjectileAttachComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	URemoteHackingResponseComponent RemoteHackingResponseComp;
	default RemoteHackingResponseComp.bCanCancel = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UHazeCameraComponent FirstPersonCameraComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent FirstPersonTransitionComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	USceneComponent ZoeButtonMashAttachComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	USceneComponent MioButtonMashAttachComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Hips")
	UCapsuleComponent MagnetCollider;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossChaseMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossGrabDebrisCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossVolleyCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossDonutAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossMagneticCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;

	UPROPERTY(DefaultComponent)
	UPrisonBossAttackDataComponent AttackDataComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;
	default MagneticFieldResponseComp.bMagnetized = false;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MagneticMaterial;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureDarkMioScythe AnimFeature;

	UPROPERTY()
	FPrisonBossAttackCompletedEvent OnAttackCompleted;

	UPROPERTY()
	FPrisonBossGrabbedPlayerEvent OnGrabbedPlayer;

	UPROPERTY()
	FPrisonBossStunnedEvent OnStunned;

	UPROPERTY()
	FPrisonBossRecoveredFromStunEvent OnRecoveredFromStun;

	UPROPERTY()
	FPrisonBossSequenceCompletedEvent OnSequenceCompleted;

	UPROPERTY()
	FPrisonBossAttackTriggeredEvent OnAttackTriggered;

	UPROPERTY()
	FPrisonBossMagneticProjectileHitEvent OnHitByProjectile;

	UPROPERTY()
	FPrisonBossMagneticProjectileHitEvent OnMagneticProjectileHitPlayer;

	UPROPERTY()
	FPrisonBossPlayerLostControlEvent OnPlayerLostControl;

	UPROPERTY()
	FPrisonBossPhaseCompletedEvent OnFirstPhaseCompleted;

	UPROPERTY()
	FPrisonBossPhaseCompletedEvent OnSecondPhaseCompleted;

	UPROPERTY()
	FPrisonBossPhaseCompletedEvent OnThirdPhaseCompleted;

	UPROPERTY()
	FPrisonBossMagnetBlastedEvent OnMagnetBlasted;

	UPROPERTY()
	FPrisonBossMagnetBlastedEvent OnMagnetReset;

	UPROPERTY()
	FPrisonBossMagneticProjectileHitEvent OnHitByHackableMagneticProjectile;

	UPROPERTY(EditInstanceOnly)
	AActor MiddlePoint;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor CircleSplineAirInner;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor CircleSplineAirOuterUpper;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor CircleSplineAirOuterLower;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor CircleSplineGroundInner;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor SpiralSpline;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	TArray<ASplineActor> ZigZagSplines;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	TArray<ASplineActor> BendSplines;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	TArray<ASplineActor> FlowerSplines;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	TArray<ASplineActor> PentagramSplines;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor ZigZagSpline;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor ChaseSpline;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	ASplineActor PlayerRespawnSpline;

	UPROPERTY(EditInstanceOnly)
	AActor MiddlePlatform;

	UPROPERTY(EditInstanceOnly)
	AActor LeftPlatform;

	UPROPERTY(EditInstanceOnly)
	AActor RightPlatform;

	TArray<AActor> Platforms;

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
	UHazeCameraSpringArmSettingsDataAsset TakeControlCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBarWidget;
	UPROPERTY(EditDefaultsOnly)
	FText HealthBarName;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SpiralCurve;

	UPROPERTY()
	FPrisonBossHackedEvent OnHacked;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface FirstPersonPostProcessMat;

	UPROPERTY(EditDefaultsOnly)
	FText GrabDebrisText;

	UPROPERTY(EditDefaultsOnly)
	FText ReleaseDebrisText;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> ElectricitySoftDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> ElectricitySoftDeathEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> ElectricityImpactDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> ElectricityImpactDeathEffect;

	// VO Actors to allow dark mio to talk with an alternative voice
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APrisonBossVoActor> VoActorClass;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	APrisonBossVoActor VoActor;

	EPrisonBossAttackType CurrentAttackType;

	FPrisonBossAnimationData AnimationData;

	bool bHacked = false;
	bool bControlled = false;

	bool bStunned = false;
	bool bStunnedAirborne = false;

	TArray<EPrisonBossAttackType> QueuedAttacks;
	TArray<EPrisonBossAttackType> CachedSequence;
	bool bAttackSequenceActive = false;

	FRotator HeadRotationOverride;

	APrisonBossPlatformDangerZone TargetDangerZone;
	bool bChargingAllDangerZones = false;

	float CurrentIdleTime = 0.0;
	float TargetIdleTime = 0.0;

	bool bVolleyActive = false;

	bool bDeflectProjectiles = false;

	AHazePlayerCharacter IdleTargetPlayer;

	bool bHackableMagneticProjectileActive = false;
	bool bMagneticProjectileHacked = false;

	int CurrentPhase = 1;
	int HitsTaken = 0;

	bool bChasing = false;
	bool bChasePaused = false;
	float DefaultChaseSplineOffset = 3600.0;
	float ChaseSplineOffset = 3600.0;
	AActor StaticChasePoint = nullptr;
	float StaticChasePointInterpSpeed = 3000.0;

	APrisonBossHackableMagneticProjectile CurrentHackableMagneticProjectile;
	int HackableMagneticProjectileIdentifier = 0;

	UPROPERTY(BlueprintReadOnly)
	int CurrentBrainPhase = 1;

	UPROPERTY(BlueprintReadOnly)
	bool bChokePhaseStarted = false;

	FPrisonBossVolleyData CurrentVolleyData;

	bool bHackable = false;
	bool bIsDeflecting = false;
	bool bHackedRotationFollowsCamera = true;
	bool bThirdPhaseCompleted = false;

	UPROPERTY(EditAnywhere)
	bool bAnimLegCablePhysicsCollision = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RemoteHackingResponseComp.Disable(this);
		RemoteHackingResponseComp.OnHackingStarted.AddUFunction(this, n"Hacked");
		RemoteHackingResponseComp.SetAbsolute(false, true, false);

		IdleTargetPlayer = Game::Zoe;

		HealthBarWidget = Widget::AddFullscreenWidget(HealthBarClass);
		HealthBarWidget.InitBossHealthBar(HealthBarName, 1.0, 3);

		DefaultChaseSplineOffset = ChaseSplineOffset;

		Platforms.Add(MiddlePlatform);
		Platforms.Add(LeftPlatform);
		Platforms.Add(RightPlatform);

		// Spawn and attach VO Actors
		VoActor = SpawnActor(VoActorClass, bDeferredSpawn = true);
		VoActor.MakeNetworked(this, n"VoActor");
		FinishSpawningActor(VoActor);
		VoActor.AttachToComponent(Mesh, n"Head", EAttachmentRule::SnapToTarget);
	}

	UFUNCTION()
	void StopSyncingPosition()
	{
		SyncedActorPositionComp.TransitionSync(this);
	}

	UFUNCTION()
	void UpdateIdleTargetPlayer(AHazePlayerCharacter Player)
	{
		IdleTargetPlayer = Player;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (QueuedAttacks.Num() > 0)
		{
			if (CurrentAttackType == EPrisonBossAttackType::None)
			{
				if (TargetIdleTime != 0.0)
				{
					CurrentIdleTime += DeltaTime;
					if (CurrentIdleTime >= TargetIdleTime)
						TriggerQueuedAttack();
				}
				else
				{
					TriggerQueuedAttack();
				}
			}
		}
		else
		{
			if (bAttackSequenceActive)
				AttackSequenceCompleted();
		}

		TEMPORAL_LOG(this)
			.Value("HitsTaken", HitsTaken)
			.Value("CurrentAttackType", CurrentAttackType)
		;
	}

	void AttackSequenceCompleted()
	{
		if (CachedSequence.Num() != 0)
			StartAttackSequence(CachedSequence, true);
		else
		{
			bAttackSequenceActive = false;
			OnSequenceCompleted.Broadcast();
		}
	}

	UFUNCTION()
	void CancelAttackSequence()
	{
		bAttackSequenceActive = false;
		QueuedAttacks.Empty();
		CachedSequence.Empty();
		CurrentAttackType = EPrisonBossAttackType::None;
	}

	void TriggerQueuedAttack()
	{
		TargetIdleTime = 0.0;
		TriggerAttack(QueuedAttacks[0]);
		QueuedAttacks.RemoveAt(0);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Hacked()
	{
		DisableHacking();
		SetHackedStatus(true);
		OnHacked.Broadcast();

		HitsTaken = 0;

		UPrisonBossEffectEventHandler::Trigger_Hacked(this);
	}

	UFUNCTION()
	void SetHackedStatus(bool bIsHacked)
	{
		bHacked = bIsHacked;

		AnimationData.bHacked = bHacked;
	}

	UFUNCTION()
	void SetControlledStatus(bool bIsControlled)
	{
		bControlled = bIsControlled;
	}

	UFUNCTION()
	void SetTargetIdleTime(float NewTime)
	{
		TargetIdleTime = NewTime;
		CurrentIdleTime = 0.0;
	}

	UFUNCTION()
	void SpawnHackableMagneticProjectile()
	{
		FVector SpawnLoc = ActorLocation + (ActorRightVector * 250.0) + FVector::UpVector * 400.0;
		CurrentHackableMagneticProjectile = SpawnActor(AttackDataComp.HackableMagneticProjectileClass, SpawnLoc, bDeferredSpawn = true);
		HackableMagneticProjectileIdentifier++;
		CurrentHackableMagneticProjectile.MakeNetworked(this, HackableMagneticProjectileIdentifier);
		FinishSpawningActor(CurrentHackableMagneticProjectile);
		CurrentHackableMagneticProjectile.AttachToComponent(Mesh, n"Align");
		
		CurrentHackableMagneticProjectile.OnHacked.AddUFunction(this, n"HackableProjectileHacked");
		CurrentHackableMagneticProjectile.OnExploded.AddUFunction(this, n"HackableProjectileExploded");

		bHackableMagneticProjectileActive = true;
	}

	UFUNCTION()
	private void HackableProjectileHacked()
	{
		bMagneticProjectileHacked = true;
		// bHackableMagneticProjectileActive = false;
	}

	UFUNCTION()
	private void HackableProjectileExploded(bool bHitBoss)
	{
		bMagneticProjectileHacked = false;
		bHackableMagneticProjectileActive = false;
	}

	UFUNCTION()
	void TriggerAttack(EPrisonBossAttackType AttackType)
	{
		CurrentAttackType = AttackType;
		OnAttackTriggered.Broadcast(CurrentAttackType);
	}

	UFUNCTION()
	void StopAttack()
	{
		CurrentAttackType = EPrisonBossAttackType::None;
	}

	UFUNCTION()
	void TriggerHackableMagneticProjectile()
	{
		CurrentAttackType = EPrisonBossAttackType::HackableMagneticProjectile;
	}

	UFUNCTION()
	void TriggerPlatformDangerZone()
	{
		CurrentAttackType = EPrisonBossAttackType::PlatformDangerZone;
	}
	
	UFUNCTION()
	void TriggerInactiveDangerZones()
	{
		TArray<APrisonBossPlatformDangerZone> DangerZones = TListedActors<APrisonBossPlatformDangerZone>().Array;
		DangerZones.Remove(TargetDangerZone);

		for (APrisonBossPlatformDangerZone DangerZone : DangerZones)
		{
			DangerZone.ActivateDangerZone(4.0);
		}

		UPrisonBossEffectEventHandler::Trigger_PlatformDangerZoneInactiveZonesTriggered(this);
	}

	UFUNCTION()
	void EnableHacking()
	{
		if (bHacked)
			return;

		RemoteHackingResponseComp.Enable(this);
		BP_EnableHacking();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EnableHacking() {}

	UFUNCTION()
	void DisableHacking()
	{
		if (bHacked)
			return;			

		RemoteHackingResponseComp.bAllowHacking = false;
		RemoteHackingResponseComp.Disable(this);
	}

	UFUNCTION()
	void UpdateHealth(float NewHealth)
	{
		HealthBarWidget.SetHealthAsDamage(NewHealth);
	}

	UFUNCTION()
	void RemoveHealthBar()
	{
		if (HealthBarWidget != nullptr)
			Widget::RemoveFullscreenWidgetSkipAnimation(HealthBarWidget);
	}

	void HitByProjectile()
	{
		AnimationData.bHackableMagneticProjectileHitReaction = true;

		OnHitByProjectile.Broadcast();

		HealthBarWidget.TakeDamage((1.0/3.0)/3.0);
		
		HitsTaken++;
		if (HitsTaken >= 3)
		{
			if (HasControl())
				CrumbCompleteFirstPhase();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbCompleteFirstPhase()
	{
		OnFirstPhaseCompleted.Broadcast();
	}

	void HitByDeflectedProjectile()
	{
		if (bStunned)
			return;

		OnHitByProjectile.Broadcast();

		if (CurrentAttackType == EPrisonBossAttackType::GrabDebris)
		{
			UPrisonBossEffectEventHandler::Trigger_GrabDebrisHit(this);
			
			DeactivateVolley();

			HealthBarWidget.TakeDamage(1.0/6.0);

			SetAnimBoolParam(n"Hit", true);
			bHackable = true;

			Timer::SetTimer(this, n"EnableHacking", 1.8);

			TriggerFeedback(EPrisonBossFeedbackType::Medium);

			return;
		}
		else if (bHacked)
		{
			UPrisonBossEffectEventHandler::Trigger_TakeControlHitBoss(this);
		}

		HealthBarWidget.TakeDamage((1.0/3.0)/2.0);

		HitsTaken++;
		if (HitsTaken >= 2)
		{
			if (bHacked)
			{
				if (Game::Zoe.HasControl())
					CrumbCompleteThirdPhase();
			}
		}
		else
		{
			SetAnimBoolParam(n"Hit", true);
			Timer::SetTimer(this, n"DelayedControlLoss", 1.2);
			Game::Mio.PlayCameraShake(HeavyCameraShake, this);
			Game::Mio.PlayForceFeedback(HeavyForceFeedback, false, true, this);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbCompleteThirdPhase()
	{
		SetAnimBoolParam(n"Hit", true);
		Game::Mio.PlayCameraShake(HeavyCameraShake, this);
		Game::Mio.PlayForceFeedback(HeavyForceFeedback, false, true, this);

		bThirdPhaseCompleted = true;
		OnThirdPhaseCompleted.Broadcast();
	}

	UFUNCTION()
	void SetHitsTaken(int Hits)
	{
		HitsTaken = Hits;
	}

	UFUNCTION()
	void DelayedControlLoss()
	{
		SetControlledStatus(false);
	}

	void ProjectileHitPlayer()
	{
		OnMagneticProjectileHitPlayer.Broadcast();
	}

	UFUNCTION()
	void Stun()
	{
		if (bStunned)
			return;

		bStunnedAirborne = true;

		CancelAttackSequence();

		bStunned = true;
		OnStunned.Broadcast();
	}

	UFUNCTION()
	void RecoverFromStun()
	{
		if (!bStunned)
			return;

		bStunned = false;
		ClearHeadRotationOverride();
	}

	UFUNCTION(DevFunction)
	void MagnetOn()
	{
		MagneticFieldResponseComp.SetMagnetizedStatus(true);

		BP_MagnetOn();
	}

	UFUNCTION(DevFunction)
	void MagnetOff()
	{
		MagneticFieldResponseComp.SetMagnetizedStatus(false);

		BP_MagnetOff();
	}

	UFUNCTION(BlueprintEvent)
	void BP_MagnetOn() {}

	UFUNCTION(BlueprintEvent)
	void BP_MagnetOff() {}

	UFUNCTION(BlueprintPure)
	FVector GetDirectionToMio()
	{
		return (ActorLocation - Game::Mio.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
	}

	void TriggerFeedback(EPrisonBossFeedbackType Type, float Intensity = 1.0, EHazeSelectPlayer Player = EHazeSelectPlayer::Both)
	{
		TSubclassOf<UCameraShakeBase> ShakeClass;
		UForceFeedbackEffect FFEffect;
		switch (Type)
		{
			case EPrisonBossFeedbackType::Light:
				ShakeClass = LightCameraShake;
				FFEffect = LightForceFeedback;
			break;
			case EPrisonBossFeedbackType::Medium:
				ShakeClass = MediumCameraShake;
				FFEffect = MediumForceFeedback;
			break;			
			case EPrisonBossFeedbackType::Heavy:
				ShakeClass = HeavyCameraShake;
				FFEffect = HeavyForceFeedback;
			break;
		}

		switch (Player)
		{
			case EHazeSelectPlayer::Mio:
				Game::Mio.PlayCameraShake(ShakeClass, this, Intensity);
				Game::Mio.PlayForceFeedback(FFEffect, false, true, this, Intensity);
			break;
			case EHazeSelectPlayer::Zoe:
				Game::Zoe.PlayCameraShake(ShakeClass, this, Intensity);
				Game::Zoe.PlayForceFeedback(FFEffect, false, true, this, Intensity);
			break;
			case EHazeSelectPlayer::Both:
				Game::Mio.PlayCameraShake(ShakeClass, this, Intensity);
				Game::Mio.PlayForceFeedback(FFEffect, false, true, this, Intensity);
				Game::Zoe.PlayCameraShake(ShakeClass, this, Intensity);
				Game::Zoe.PlayForceFeedback(FFEffect, false, true, this, Intensity);
			break;
			case EHazeSelectPlayer::None:
			break;
			case EHazeSelectPlayer::Specified:
			break;
		}
	}

	UFUNCTION()
	void StartAttackSequence(TArray<EPrisonBossAttackType> Attacks, bool bLoop = false)
	{
		bAttackSequenceActive = true;
		QueuedAttacks = Attacks;

		if (bLoop)
			CachedSequence = Attacks;
	}

	UFUNCTION()
	void ClearAttackSequence()
	{
		bAttackSequenceActive = false;
		CachedSequence.Empty();
		QueuedAttacks.Empty();
	}

	UFUNCTION(BlueprintEvent)
	void BP_FinalCloneAttack() {}

	UFUNCTION(BlueprintEvent)
	void BP_GroundTrailSlam() {}

	UFUNCTION(BlueprintEvent)
	void BP_MagneticSlam() {}

	UFUNCTION()
	void ActivateMainPlatformRespawn()
	{
		FOnRespawnOverride RespawnOverrideDelegate;
		RespawnOverrideDelegate.BindUFunction(this, n"HandleRespawn");
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverrideDelegate);
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		float Fraction = Math::Wrap((PlayerRespawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation)/PlayerRespawnSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
		FVector RespawnLoc = PlayerRespawnSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
		FRotator RespawnRot = (MiddlePoint.ActorLocation - RespawnLoc).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
		FTransform RespawnTransform = FTransform(FQuat(RespawnRot), RespawnLoc, FVector::OneVector);

		OutLocation.RespawnTransform = RespawnTransform;

		return true;
	}

	UFUNCTION()
	void DeactivateMainPlatformRespawn()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ClearRespawnPointOverride(this);
	}

	UFUNCTION()
	void StartChase(bool bSnap)
	{
		bChasing = true;

		if (bSnap)
		{
			AHazePlayerCharacter ClosestPlayer = GetDistanceTo(Game::Mio) > GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;

			FVector DirToPlayer = (ClosestPlayer.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			SetActorRotation(DirToPlayer.Rotation());

			float SplineDist = ChaseSpline.Spline.GetClosestSplineDistanceToWorldLocation(ClosestPlayer.ActorLocation) + ChaseSplineOffset;
			SetActorLocation(ChaseSpline.Spline.GetWorldLocationAtSplineDistance(SplineDist));
		}
	}

	UFUNCTION()
	void PauseChase()
	{
		bChasePaused = true;
	}

	UFUNCTION()
	void ResumeChase()
	{
		bChasePaused = false;
	}

	UFUNCTION()
	void SetStaticChasePoint(AActor NewPoint, float Speed = 1.0)
	{
		StaticChasePointInterpSpeed = Speed;
		StaticChasePoint = NewPoint;
	}

	UFUNCTION()
	void ClearStaticChasePoint()
	{
		StaticChasePoint = nullptr;
	}

	UFUNCTION()
	void UpdateChaseDistanceOffset(float NewOffset)
	{
		ChaseSplineOffset = NewOffset;
	}

	UFUNCTION()
	void ResetChaseDistanceOffset()
	{
		ChaseSplineOffset = DefaultChaseSplineOffset;
	}

	UFUNCTION()
	void StopChase()
	{
		bChasing = false;
	}

	UFUNCTION()
	void OverrideHeadRotation(FRotator Rot)
	{
		HeadRotationOverride = Rot;
	}

	UFUNCTION()
	void ClearHeadRotationOverride()
	{
		HeadRotationOverride = FRotator::ZeroRotator;
	}

	UFUNCTION()
	void UpdateMiddlePoint(AActor NewPoint)
	{
		MiddlePoint = NewPoint;
	}

	UFUNCTION()
	void SetChokePhaseStarted()
	{
		bChokePhaseStarted = true;
	}

	UFUNCTION()
	void ChokeSlam()
	{
		UPrisonBossEffectEventHandler::Trigger_GrabPlayerSlam(this);
	}

	UFUNCTION()
	void NeckSnap()
	{
		UPrisonBossEffectEventHandler::Trigger_GrabPlayerNeckSnap(this);
	}

	UFUNCTION()
	void RocketFistImpact()
	{
		UPrisonBossEffectEventHandler::Trigger_RocketFistImpact(this);
	}

	UFUNCTION()
	void RocketFistMioLanding()
	{
		UPrisonBossEffectEventHandler::Trigger_RocketFistMioLanding(this);
	}

	UFUNCTION()
	void ResetPlayerMovement(AHazePlayerCharacter Player)
	{
		Player.ResetMovement();
	}

	UFUNCTION()
	void SetControlPlayer(AHazePlayerCharacter Player)
	{
		if (HasControl())
			CrumbChangeControlSide(Player);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbChangeControlSide(AHazePlayerCharacter Player)
	{
		SetActorControlSide(Player);
	}

	UFUNCTION(BlueprintPure)
	bool IsHacked()
	{
		return bHacked;
	}

	UFUNCTION()
	void UpdateDangerZone(APrisonBossPlatformDangerZone DangerZone)
	{
		TargetDangerZone = DangerZone;
	}

	UFUNCTION()
	void ActivateFirstPersonCamera(AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(FirstPersonCameraComp, 0.0, this, EHazeCameraPriority::High);
	}

	UFUNCTION(DevFunction)
	void DevStartSpawningDonuts()
	{
		StartSpawningDonuts();
	}

	UFUNCTION()
	void StartSpawningDonuts()
	{
		CurrentAttackType = EPrisonBossAttackType::Donut;
	}

	UFUNCTION()
	void StopSpawningDonuts()
	{
		CurrentAttackType = EPrisonBossAttackType::None;
	}

	UFUNCTION()
	void ActivateVolley(FPrisonBossVolleyData VolleyData = FPrisonBossVolleyData())
	{
		CurrentVolleyData = VolleyData;
		bVolleyActive = true;
	}

	UFUNCTION()
	void UpdateVolleyData(FPrisonBossVolleyData Data)
	{
		CurrentVolleyData = Data;
	}

	UFUNCTION()
	void DeactivateVolley()
	{
		bVolleyActive = false;
		UPrisonBossEffectEventHandler::Trigger_VolleyWaveDispersed(this);
	}

	UFUNCTION()
	void StartGrabbingDebris()
	{
		TriggerAttack(EPrisonBossAttackType::GrabDebris);
	}

	UFUNCTION()
	void SetDeflectStatus(bool bNewStatus)
	{
		bDeflectProjectiles = bNewStatus;
	}

	UFUNCTION()
	void SetBrainPhase(int Phase)
	{
		CurrentBrainPhase = Phase;
	}

	UFUNCTION(BlueprintPure)
	bool IsStunned()
	{
		return bStunned;
	}

	UFUNCTION(BlueprintPure)
	bool IsBrainButtonCoverOpen()
	{
		TArray<APrisonBossBrainButtonCover> Covers = TListedActors<APrisonBossBrainButtonCover>().Array;
		bool bCoverOpen = false;
		for (APrisonBossBrainButtonCover Cover : Covers)
		{
			if (Cover.bOpen)
				bCoverOpen = true;
		}
			
		return bCoverOpen;
	}

	UFUNCTION(DevFunction)
	void DevGrabPlayer() {TriggerAttack(EPrisonBossAttackType::GrabPlayer);}

	UFUNCTION(DevFunction)
	void DevTriggerSpiralAttack() {TriggerAttack(EPrisonBossAttackType::Spiral);}

	UFUNCTION(DevFunction)
	void DevTriggerWaveSlash() {TriggerAttack(EPrisonBossAttackType::WaveSlash);}

	UFUNCTION(DevFunction)
	void DevTriggerClone() {TriggerAttack(EPrisonBossAttackType::Clone);}

	UFUNCTION(DevFunction)
	void DevTriggerGroundTrail() {TriggerAttack(EPrisonBossAttackType::GroundTrail);}

	UFUNCTION(DevFunction)
	void DevTriggerHackableMagneticProjectile() {TriggerHackableMagneticProjectile();}

	UFUNCTION(DevFunction)
	void DevEnableHacking() {EnableHacking();}

	UFUNCTION(DevFunction)
	void DevTriggerDashSlash() {TriggerAttack(EPrisonBossAttackType::DashSlash);}

	UFUNCTION(DevFunction)
	void DevTriggerHorizontalSlash() {TriggerAttack(EPrisonBossAttackType::HorizontalSlash);}

	UFUNCTION(DevFunction)
	void DevTriggerMagneticSlam() {TriggerAttack(EPrisonBossAttackType::MagneticSlam);}

	UFUNCTION(DevFunction)
	void DevTriggerPlatformDangerZone() {TriggerPlatformDangerZone();}

	UFUNCTION(DevFunction)
	void DevActivateVolley() {ActivateVolley();}

	UFUNCTION(DevFunction)
	void DevTriggerZigZag() {TriggerAttack(EPrisonBossAttackType::ZigZag);}

	UFUNCTION(DevFunction)
	void DevTriggerScissors() {TriggerAttack(EPrisonBossAttackType::Scissors);}

	UFUNCTION(DevFunction)
	void DevStun()
	{
		if (bHacked)
			HitByDeflectedProjectile();
		else
			Stun();
	}

	//Functions for external effect events
	UFUNCTION()
	void EyeRippedOut()
	{
		UPrisonBossEffectEventHandler::Trigger_BrainEyeRippedOut(this);
	}
	UFUNCTION()
	void ButtonCoverOpened()
	{
		UPrisonBossEffectEventHandler::Trigger_BrainButtonCoverOpened(this);
	}
	UFUNCTION()
	void ButtonPushed()
	{
		UPrisonBossEffectEventHandler::Trigger_BrainButtonPushed(this);
	}
	UFUNCTION()
	void BrainOpened()
	{
		UPrisonBossEffectEventHandler::Trigger_BrainOpened(this);
	}
	UFUNCTION()
	void BrainHacked()
	{
		UPrisonBossEffectEventHandler::Trigger_BrainHacked(this);
	}

}

enum EPrisonBossFeedbackType
{
	Light,
	Medium,
	Heavy
}