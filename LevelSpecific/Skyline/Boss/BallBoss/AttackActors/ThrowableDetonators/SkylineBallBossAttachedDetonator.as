class ASkylineBallBossAttachedDetonator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachedRoot;

	UPROPERTY(DefaultComponent, Attach = AttachedRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = AttachedRoot)
	UHazeDecalComponent DecalComp;

	UPROPERTY(DefaultComponent, Attach = AttachedRoot)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent,Attach = MeshComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	UNiagaraSystem HitVFXSystem;

	UPROPERTY()
	UNiagaraSystem CritVFXSystem;

	UPROPERTY()
	UNiagaraSystem ExplosionVFXSystem;

	UPROPERTY()
	UMaterialInterface HitMaterial;

	UPROPERTY()
	UMaterialInterface DetachedMaterial;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> DetonatorWidgetClass;
	UHazeUserWidget DetonatorWidget;
	bool bShowingWidget = false;

	UPROPERTY()
	float StickyDuration = 3.0;

	UPROPERTY()
	float ShakeDuration = 2.0;

	float AliveDuration = 0.0;

	bool bShaky = false;
	bool bActivated = false;
	bool bDetached = false;

	ASkylineBallBoss BallBoss;
	bool bHit = false;
	bool bWincedFromHit = false;
	bool bRemovedWince = false;
	USkylineBallBossDetonatorSocketComponent DibbedSocket = nullptr;

	FVector FallStartLocation;
	FVector FallStartForward;
	FVector FallStartVelocity;
	FQuat FallStartQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		BladeResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		TListedActors<ASkylineBallBoss> BallBosses;
		BallBoss = BallBosses.Single;
		SetActorControlSide(Game::Mio);

		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::RemoveDetonator, ESkylineBallBossBlinkPriority::Higher);
		USkylineBallBossAttachedDetonatorEventHandler::Trigger_OnSpawned(this);

		USkylineBallBossMiscVOEventHandler::Trigger_DetonatorHit(BallBoss);

		QueueComp.Duration(0.3, this, n"UpdateLegs");
		
		AddEyeWidget();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (IsValid(BallBoss)) // restart from progress point issue
		{
			BallBoss.RemoveBlink(this);
			BallBoss.RemoveBlink(this);
			BallBoss.RemoveBlink(this);
		}
	}

	private void AddEyeWidget()
	{
		bShowingWidget = true;
		DetonatorWidget = Game::Mio.AddWidget(DetonatorWidgetClass);
		DetonatorWidget.AttachWidgetToActor(this);
		DetonatorWidget.SetWidgetRelativeAttachOffset(FVector::ForwardVector * 50.0);
	}

	private void RemoveDetonatorWidget()
	{
		if (!bShowingWidget)
			return;

		Game::Mio.RemoveWidget(DetonatorWidget);
		bShowingWidget = false;
	}

	UFUNCTION()
	private void UpdateLegs(float Alpha)
	{
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 1.0);
		BP_UpdateLegs(CurrentValue);
	}

	UFUNCTION()
	private void HandleMioReachedInside()
	{
	}

	void Disintegrate()
	{
		USkylineBallBossAttachedDetonatorEventHandler::Trigger_OnEvaporateDisintegrate(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, MeshComp.WorldLocation);
		SetAutoDestroyWhenFinished(true);
	}

	void BlinkImpact()
	{
		USkylineBallBossAttachedDetonatorEventHandler::Trigger_OnBossBlinkImpact(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bWincedFromHit && IsOnEye())
		{
			bWincedFromHit = true;
			BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateOpen, ESkylineBallBossBlinkPriority::Highest);
		}
		AliveDuration += DeltaSeconds;
		if (AliveDuration > 0.1 && bWincedFromHit && !bRemovedWince)
		{
			bRemovedWince = true;
			BallBoss.RemoveBlink(this, ESkylineBallBossBlinkExpression::StateOpen);
		}

		if (!IsOnEye() && !bDetached)
			Detach();
		
		if (BallBoss.DisintegrationRadius > KINDA_SMALL_NUMBER && BallBoss.DisintegrationRadius > (BallBoss.ActorLocation - ActorLocation).Size())
			Disintegrate();

		// Debug::DrawDebugSphere(BallBoss.HatchLocationComp.WorldLocation, 260.0, 12, ColorDebug::Carrot, 10.0, 0.0, true);

		if (GameTimeSinceCreation > StickyDuration && !bActivated)
			bShaky = true;

		if (GameTimeSinceCreation > StickyDuration + ShakeDuration && !bActivated)
			Detach();

		if (bShaky)
			MeshComp.SetRelativeRotation(FRotator(0.0, Math::Sin(Time::GameTimeSeconds * 25.0) * 20.0, 0.0));

		if (GameTimeSinceCreation > (StickyDuration + ShakeDuration) * 2.0 && !bActivated)
			DestroyActor();
	}

	UFUNCTION()
	private void Detach()
	{
		bDetached = true;
		bShaky = false;
		SetActorTickEnabled(false);
		SetActorEnableCollision(false);
		DetachFromActor(EDetachmentRule::KeepWorld);

		BladeResponseComp.AddResponseComponentDisable(this);
		MeshComp.SetMaterial(1, DetachedMaterial);
		BallBoss.RemoveBlink(this, ESkylineBallBossBlinkExpression::RemoveDetonator);
		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateSquint, ESkylineBallBossBlinkPriority::High);
		if (DibbedSocket != nullptr)
		{
			if (DibbedSocket.AutoAimChildComp != nullptr)
				DibbedSocket.AutoAimChildComp.Enable(BallBoss);
			DibbedSocket.AttachedDetonator = nullptr;
			DibbedSocket = nullptr;
		}
		USkylineBallBossAttachedDetonatorEventHandler::Trigger_OnDetached(this);

		FallStartLocation = ActorLocation;
		FallStartForward = ActorForwardVector;
		FallStartQuat = ActorQuat;
		FallStartVelocity = VelocityTrackerComp.GetLastFrameTranslationVelocity();


		QueueComp.Duration(3.0, this, n"FallOffUpdate");
		QueueComp.Event(this, n"Explode");

		RemoveDetonatorWidget();
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		bActivated = true;
		bShaky = false;
		bHit = true;

		BladeResponseComp.AddResponseComponentDisable(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitVFXSystem, ActorLocation);

		DecalComp.SetHiddenInGame(false);
		USkylineBallBossAttachedDetonatorEventHandler::Trigger_OnBladeHit(this);
		
		Timer::SetTimer(this, n"Explode", 0.3);
		//Explode();
		BP_Hit();

		RemoveDetonatorWidget();
	}
	
	UFUNCTION()
	private void FallOffUpdate(float Alpha)
	{
		float Height = Math::EaseIn(0.0, -8000.0, Alpha, 2.0);
		float Forward = Math::EaseOut(0.0, 1000.0, Alpha, 6.0);
		float RotationDegrees = Math::EaseOut(0.0, -650.0, Alpha, 2.0);
		FVector VelocityMove = FallStartVelocity * Math::EaseOut(0.0, 2.0, Alpha, 2.0);
		
		FVector Location = FallStartLocation;
		Location += FVector::UpVector * Height;
		Location += FallStartForward * Forward;
		Location += VelocityMove;

		FVector RightVector = FallStartForward.CrossProduct(FVector::UpVector);
		FQuat AddedQuat = FQuat(RightVector, Math::DegreesToRadians(RotationDegrees));
		FQuat ModifiedQuat = FQuat::ApplyDelta(FallStartQuat, AddedQuat);

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(BallBoss);

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, Location);

		if (HitResult.bBlockingHit)
		{
			QueueComp.Empty();
			QueueComp.Event(this, n"Explode");
		}

		SetActorLocationAndRotation(Location, ModifiedQuat);
	}

	UFUNCTION()
	void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, MeshComp.WorldLocation);
		BallBoss.RemoveBlink(this);
		USkylineBallBossAttachedDetonatorEventHandler::Trigger_OnDetonate(this);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		if (DibbedSocket != nullptr)
			DibbedSocket.AttachedDetonator = nullptr;
		
		if (bHit && HasControl())
		{
			CrumbApplyBallDamage();
		}
		else if (!bHit)
			DestroyActor();
	}

	bool IsOnEye() const
	{
		return ActorLocation.Distance(BallBoss.HatchLocationComp.WorldLocation) < 260.0;
	}

	float GetFutureDamage() const
	{
		if (!bHit)
			return 0.0;

		bool bIsOnEye = IsOnEye();
		float Damage = bIsOnEye ? Settings.DetonatorDamage : Settings.DetonatorDamageOffEye;
		bool bPhase2 = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2 || BallBoss.GetPhase() == ESkylineBallBossPhase::TopGrappleFailed2;
		if (bPhase2)
			return Damage;
		bool bPhase1 = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn1 || BallBoss.GetPhase() == ESkylineBallBossPhase::TopGrappleFailed1;
		if (bPhase1)
			return Damage;
		return 0.0;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbApplyBallDamage()
	{
		USkylineBallBossMiscVOEventHandler::Trigger_DetonatorExplode(BallBoss);

		bool bIsOnEye = IsOnEye();
		float Damage = bIsOnEye ? Settings.DetonatorDamage : Settings.DetonatorDamageOffEye;

		float DamageDone = BallBoss.HealthComp.MaxHealth - BallBoss.HealthComp.CurrentHealth;
		DamageDone += Damage;

		bool bPhase2 = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2 || BallBoss.GetPhase() == ESkylineBallBossPhase::TopGrappleFailed2;
		if (bPhase2 && DamageDone + KINDA_SMALL_NUMBER >= Settings.DamageRequiredToBreakEye)
		{
			Damage = BallBoss.HealthComp.CurrentHealth - Settings.DamageRequiredToBreakEye;
			BallBoss.bRecentlyGotDetonated = true;
			BallBoss.ChangePhase(ESkylineBallBossPhase::TopMioOnEyeBroken);
			BallBoss.BreakEye(true);
			float MaxKnockDist = 150;
			if (Game::Mio.HasControl() && Game::Mio.GetDistanceTo(this) < MaxKnockDist)
			{
				FVector Outwards = Game::Mio.ActorCenterLocation - ActorLocation;
				Outwards = Outwards.VectorPlaneProject(ActorUpVector);
				const float HalfForce = 700;
				Game::Mio.ApplyKnockdown(Outwards.GetSafeNormal() * HalfForce + ActorUpVector * HalfForce, 1.0);
			}
		}
		else if (bIsOnEye)
		{
			if (CritVFXSystem != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(CritVFXSystem, ActorLocation);
			BallBoss.AddCritEffect();
		}
		else
		{
			BallBoss.AddNoCritEffect(ActorLocation);
		}

		bool bPhase1 = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn1 || BallBoss.GetPhase() == ESkylineBallBossPhase::TopGrappleFailed1;
		bool bInDamagingPhase = bPhase1 || bPhase2;

		if (Damage > 0.0 && bInDamagingPhase)
		{
			BallBoss.bRecentlyGotDetonated = true;
			BallBoss.HealthComp.TakeDamage(Damage, EDamageType::Default, this);
		}

		if (bPhase1 && DamageDone + KINDA_SMALL_NUMBER >= Settings.DamageRequiredToActivateShield)
			BallBoss.ChangePhase(ESkylineBallBossPhase::TopAlignMioToStage);
		
		DestroyActor();
	}

	USkylineBallBossSettings GetSettings() const property
	{
		return Cast<USkylineBallBossSettings>(
			BallBoss.GetSettings(USkylineBallBossSettings)
		);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_UpdateLegs(float Alpha){}

	UFUNCTION(BlueprintEvent)
	private void BP_Hit(){}
};