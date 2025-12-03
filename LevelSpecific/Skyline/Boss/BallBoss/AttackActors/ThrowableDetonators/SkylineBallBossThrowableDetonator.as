class ASkylineBallBossThrowableDetonator : AWhipSlingableObject
{
	UPROPERTY()
	float LifeTime = 6.0;

	UPROPERTY()
	float DamageRadius = 300.0;

	UPROPERTY()
	UNiagaraSystem ExplosionSystem;
	ASkylineBallBoss BallBoss;
	USkylineBallBossDetonatorSocketComponent DibbedSocket = nullptr;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent,Attach = MeshRoot)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	default bUseFocusLocation = false;
	bool bCrumbDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		// GravityWhipTargetComponent.Disable(this);

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		TListedActors<ASkylineBallBoss> BallBosses;
		BallBoss = BallBosses.Single;
		USkylineBallBossThrowableDetonatorEventHandler::Trigger_OnSpawned(this);

		QueueComp.Duration(0.5, this, n"BounceUpdate");
		QueueComp.Duration(0.2, this, n"FallOverUpdate");
		QueueComp.Event(this, n"Landed");
	}

	UFUNCTION()
	private void Landed()
	{
		// GravityWhipTargetComponent.Enable(this);
	}

	UFUNCTION()
	private void BounceUpdate(float Alpha)
	{
		FVector HeightVector = FVector::ForwardVector * Math::Lerp(-40.0, 160.0, Math::Sin(Alpha * PI));
		FVector SidewaysVector = FVector::UpVector * 60.0 * Alpha;
		MeshRoot.SetRelativeLocation(HeightVector + SidewaysVector);
		MeshRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, -30.0, Alpha), 0.0, 0.0));
	}

	UFUNCTION()
	private void FallOverUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 1.0);
		MeshRoot.SetRelativeRotation(FRotator(Math::Lerp(-30.0, -90.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if (!bCrumbDestroyed && HasControl() && GameTimeSinceCreation > LifeTime && !bGrabbed)
		{
			bCrumbDestroyed = true;
			CrumbExplode();
		}
		if (!bCrumbDestroyed && HasControl() && BallBoss.DisintegrationRadius > KINDA_SMALL_NUMBER && BallBoss.DisintegrationRadius > (BallBoss.ActorLocation - ActorLocation).Size())
		{
			bCrumbDestroyed = true;
			CrumbDisintegrate();
		}
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		USkylineBallBossThrowableDetonatorEventHandler::Trigger_OnPickedUp(this);
		BP_Disarm();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Disarm()
	{}

	UFUNCTION(CrumbFunction)
	void CrumbDisintegrate()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, ActorLocation);
		SetAutoDestroyWhenFinished(true);
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, ActorLocation);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		for (auto Player : Game::Players)
		{
			if (Player.ActorLocation.Distance(ActorLocation) < DamageRadius)
			{
				FVector DeathDir = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal();
				Player.KillPlayer(FPlayerDeathDamageParams(DeathDir), BallBoss.ExplosionDeathEffect);
			}
		}

		if (DibbedSocket == nullptr)
			USkylineBallBossThrowableDetonatorEventHandler::Trigger_OnDetonate(this);

		SetActorHiddenInGame(true);
		SetAutoDestroyWhenFinished(true);
	}

	void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse) override
	{
		FVector OverrideImpulse = Impulse;
		// if we're throwing ish in the right direction, pick one of the sockets and throw into that instead
		FVector ToEye = (BallBoss.HatchFrameMeshComp.WorldLocation - ActorLocation);
		float ToEyeDotProduct = ToEye.GetSafeNormal().DotProduct(Impulse.GetSafeNormal());
		// Debug::DrawDebugString(ActorLocation, "" + ToEyeDotProduct + " / " + Math::DotToDegrees(ToEyeDotProduct), FLinearColor::White, 7.0);
		if (Math::DotToDegrees(ToEyeDotProduct) < Settings.ZoeThrowDetonatorAutoAimAngle)
		{
			// FVector ImpulseDotBegin = ActorLocation + Impulse * ToEyeDotProduct;
			// FVector ImpulseDotEnd = ActorLocation + Impulse * (1.0 - ToEyeDotProduct);
			// Debug::DrawDebugLine(ActorLocation, ImpulseDotBegin, ColorDebug::Red, 5.0, 7.0);
			// Debug::DrawDebugLine(ImpulseDotBegin, ImpulseDotEnd, ColorDebug::Leaf, 5.0, 7.0);
			// Debug::DrawDebugLine(ImpulseDotBegin, BallBoss.HatchFrameMeshComp.WorldLocation, ColorDebug::Red, 5.0, 7.0);
			// Debug::DrawDebugLine(ActorLocation, BallBoss.HatchFrameMeshComp.WorldLocation, ColorDebug::Red, 5.0, 7.0);

			OverrideImpulse = FindFreeSocket(Impulse);
			if (OverrideImpulse.Size() < KINDA_SMALL_NUMBER)
				OverrideImpulse = Impulse;
			BallBoss.FreezeRotationRequesters.Add(this);
			Timer::SetTimer(this, n"RemoveFreeze", 1.5);
			OnDestroyed.AddUFunction(this, n"HandleDestroyed");
			BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateOpen, ESkylineBallBossBlinkPriority::High);
		}
		if (TargetComponent != nullptr)
			GravityWhipTargetComponent.Disable(BallBoss);

		USkylineBallBossThrowableDetonatorEventHandler::Trigger_OnThrown(this);
		Super::OnThrown(UserComponent, TargetComponent, HitResult, OverrideImpulse);
	}

	FVector FindFreeSocket(FVector Impulse)
	{
		if (BallBoss.DetonatorSocketComp1.CanTarget())
		{
			DibbedSocket = BallBoss.DetonatorSocketComp1;
			BallBoss.DetonatorSocketComp1.IncomingDetonator = this;
			return (BallBoss.DetonatorSocketComp1.WorldLocation - ActorLocation).GetSafeNormal() * Impulse.Size();
		}
		if (BallBoss.DetonatorSocketComp2.CanTarget())
		{
			DibbedSocket = BallBoss.DetonatorSocketComp2;
			BallBoss.DetonatorSocketComp2.IncomingDetonator = this;
			return (BallBoss.DetonatorSocketComp2.WorldLocation - ActorLocation).GetSafeNormal() * Impulse.Size();
		}
		if (BallBoss.DetonatorSocketComp3.CanTarget())
		{
			DibbedSocket = BallBoss.DetonatorSocketComp3;
			BallBoss.DetonatorSocketComp3.IncomingDetonator = this;
			return (BallBoss.DetonatorSocketComp3.WorldLocation - ActorLocation).GetSafeNormal() * Impulse.Size();
		}
		return FVector::ZeroVector;
	}

	UFUNCTION()
	void RemoveFreeze()
	{
		if (BallBoss != nullptr && BallBoss.FreezeRotationRequesters.Contains(this))
			BallBoss.FreezeRotationRequesters.Remove(this);

		BallBoss.RemoveBlink(this);
	}
	
	UFUNCTION()
	private void HandleDestroyed(AActor DestroyedActor)
	{
		if (!IsValid(BallBoss)) // restart from progress point issue
			return;
		if (DibbedSocket != nullptr)
			DibbedSocket.IncomingDetonator = nullptr;
		RemoveFreeze();
	}

	USkylineBallBossSettings GetSettings() const property
	{
		return Cast<USkylineBallBossSettings>(
			BallBoss.GetSettings(USkylineBallBossSettings)
		);
	}
};