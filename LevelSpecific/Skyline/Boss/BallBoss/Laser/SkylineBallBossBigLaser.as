event void FSetLaserEnabledSignature(bool bEnabled);

class ASkylineBallBossBigLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = SoulRootComp)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = SoulRootComp)
	UStaticMeshComponent TelegraphLaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = LaserMeshComp)
	UHazeCapsuleCollisionComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = LaserMeshComp)
	UHazeSphereCollisionComponent ImpactCollisionComp;
	default ImpactCollisionComp.SphereRadius = 200.0;

	UPROPERTY(DefaultComponent, Attach = LaserMeshComp)
	UNiagaraComponent LaserImpactVFXComp;

	UPROPERTY(DefaultComponent, Attach = LaserImpactVFXComp)
	UDecalTrailComponent LaserTrailComp;

	UPROPERTY(DefaultComponent, Attach = TelegraphLaserMeshComp)
	UNiagaraComponent TelegraphLaserImpactVFXComp;

	UPROPERTY(DefaultComponent, Attach = TelegraphLaserImpactVFXComp)
	UDecalTrailComponent TelegraphLaserTrailComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SoulRootComp;

	UPROPERTY(DefaultComponent, Attach = Root) 
	UStaticMeshComponent TrailerWhiteOut;
	default TrailerWhiteOut.CollisionEnabled = ECollisionEnabled::NoCollision;
	default TrailerWhiteOut.bHiddenInGame = true;
	default TrailerWhiteOut.bVisible = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	float LaserScale = 3.0;

	ASkylineBallBossTopLaserSpline OverrideLaserSpline = nullptr;
	bool bRetracing = false;

	ASkylineBallBoss BallBoss;
	FVector BallBossStartForward;

	FSetLaserEnabledSignature OnLaserEnabled;

	UPROPERTY()
	FHazeTimeLike LaserSpeedTimeLike;
	default LaserSpeedTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeTimeLike LaserRetraceSpeedTimeLike;
	default LaserRetraceSpeedTimeLike.Duration = 0.7;

	UPROPERTY()
	FHazeTimeLike HideSoulTimeLike;
	default HideSoulTimeLike.UseSmoothCurveZeroToOne();
	default HideSoulTimeLike.Duration = 0.5;

	FHazeAcceleratedFloat AccLaserScale;
	float ScaleTarget = 0.0;
	const float DefaultFadeTime = 0.3;
	float FadeTime = DefaultFadeTime;
	
	UPROPERTY()
	float TargetIrisOffset = 700.0;
	float IrisOffset = 700.0;

	UPROPERTY()
	float LaserSpeed = 1000.0;
	float CurrentLaserSpeed = 0.0;

	UPROPERTY()
	float ChaseLaserDamage = 1.0;

	UPROPERTY()
	float ChaseLaserDamageCooldown = 0.75;

	UPROPERTY()
	float RetraceLaserDamage = 0.6;

	UPROPERTY()
	float RetraceLaserDamageCooldown = 0.75;

	float ProgressAlongSpline;

	bool bActive = false;
	bool bHadImpact = false;

	float LaserXYScale = 1.0;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter ChaseTargetPlayer = nullptr;

	TPerPlayer<float> LastTimeHitPlayer;
	TArray<AHazePlayerCharacter> ChaseOverlappedPlayers;
	TArray<USkylineBallBossLaserResponseComponent> OverlappedResponders;
	default ChaseOverlappedPlayers.Reserve(2);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserSpeedTimeLike.BindUpdate(this, n"LaserSpeedTimeLikekeUpdate");
		LaserSpeedTimeLike.BindFinished(this, n"LaserSpeedTimeLikeFinished");
		LaserRetraceSpeedTimeLike.BindUpdate(this, n"LaserSpeedTimeLikekeUpdate");
		LaserRetraceSpeedTimeLike.BindFinished(this, n"LaserRetraceSpeedTimeLikeFinished");
		HideSoulTimeLike.BindUpdate(this, n"HideSoulTimeLikeUpdate");
		CollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"ChaseLaserBeginOverlap");
		CollisionComp.OnComponentEndOverlap.AddUFunction(this, n"ChaseLaserEndOverlap");
		ImpactCollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"RetraceLaserBeginOverlap");
		BallBoss = Cast<ASkylineBallBoss>(AttachParentActor);
		BallBoss.BigLaserActor = this;
		BallBossStartForward = BallBoss.ActorForwardVector;
		BallBoss.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
		
		SetActorTickEnabled(false);
		BallBoss.OnSplineChaseEvent.AddUFunction(this, n"SplineEventTriggered");

		LaserXYScale = LaserMeshComp.WorldScale.X;
		AccLaserScale.SnapTo(0.0);

		LaserMeshComp.SetVisibility(false);
		TelegraphLaserMeshComp.SetVisibility(false);
		SoulRootComp.SetRelativeLocation(FVector::UpVector * TargetIrisOffset);

		ImpactCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		DeactivateLaserImpact();
		LaserTrailComp.bSpawnDecals = false;
		LaserTrailComp.Clear();
		TelegraphLaserTrailComp.bSpawnDecals = false;
		TelegraphLaserTrailComp.Clear();

		ChaseTargetPlayer = Game::GetMio();
	}

	UFUNCTION()
	private void HandlePhaseChanged(ESkylineBallBossPhase NewPhase)
	{
		if (NewPhase == ESkylineBallBossPhase::TopMioOnEyeBroken)
		{
			HideSoulTimeLike.Play();
		}

		if (NewPhase == ESkylineBallBossPhase::TopMioIn)
		{
			HideSoulTimeLike.Reverse();
		}
	}

	UFUNCTION()
	private void HideSoulTimeLikeUpdate(float CurrentValue)
	{
		FVector SideOffset = FVector::ForwardVector * 400.0 * CurrentValue;
		SoulRootComp.SetRelativeLocation(FVector::UpVector * IrisOffset + SideOffset);
	}

	UFUNCTION()
	private void SplineEventTriggered(ESkylineBallBossChaseEventType EventType, FSkylineBallBossChaseSplineEventData EventData)
	{
		if (EventType == ESkylineBallBossChaseEventType::DeactivateLaser)
		{
			DeactivateLaser();
			if (EventData.Float > KINDA_SMALL_NUMBER)
				Timer::SetTimer(this, n"ActivateLaser", EventData.Float);
			return;
		}

		if (EventType == ESkylineBallBossChaseEventType::ActivateLaser)
		{
			ActivateLaser();
			if (EventData.Float > KINDA_SMALL_NUMBER)
				FadeTime = EventData.Float;
			return;
		}
	}

	UFUNCTION()
	private void ChaseLaserBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		if (!bActive)
			return;
		
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			ChaseOverlappedPlayers.AddUnique(Player);

		auto LazerResponder = Cast<USkylineBallBossLaserResponseComponent>(OtherComp);
		if (LazerResponder != nullptr)
		{
			OverlappedResponders.AddUnique(LazerResponder);
			LazerResponder.LaserOverlap(true);
		}
	}

	UFUNCTION()
	private void ChaseLaserEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                               UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (!bActive)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && ChaseOverlappedPlayers.Contains(Player))
			ChaseOverlappedPlayers.Remove(Player);		

		auto LazerResponder = Cast<USkylineBallBossLaserResponseComponent>(OtherComp);
		if (LazerResponder != nullptr)
		{
			OverlappedResponders.Remove(LazerResponder);
			LazerResponder.LaserOverlap(false);
		}
	}

	UFUNCTION()
	private void RetraceLaserBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Time::GetGameTimeSince(LastTimeHitPlayer[Player]) > RetraceLaserDamageCooldown)
			{
				Player.DamagePlayerHealth(RetraceLaserDamage, FPlayerDeathDamageParams(LaserMeshComp.UpVector), BallBoss.LaserHeavyDamageEffect, BallBoss.LaserHeavyDeathEffect);
				Player.ApplyKnockdown(FVector::RightVector * 800.0 + FVector::UpVector * 300.0, 1.5);
				LastTimeHitPlayer[Player] = Time::GameTimeSeconds;
			}
		}
	}

	UFUNCTION()
	private void LaserSpeedTimeLikekeUpdate(float CurrentValue)
	{
		if (GetSpline() != nullptr)
			ProgressAlongSpline = GetSpline().SplineLength * Math::Clamp(CurrentValue, 0.0, 1.0);
	}

	UFUNCTION()
	private void LaserSpeedTimeLikeFinished()
	{
		if (BallBoss.GetPhase() > ESkylineBallBossPhase::Chase && ShouldRetrace())
		{
			bRetracing = true;
			TelegraphLaserMeshComp.SetVisibility(false);
			TelegraphLaserTrailComp.bSpawnDecals = false;
			OverrideLaserSpline.RetraceLaserSpeedTimeLike.PlayFromStart();
			ImpactCollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
			ActivateRetraceLaser();
		}
	}

	UFUNCTION()
	private void LaserRetraceSpeedTimeLikeFinished()
	{
		bRetracing = false;
	}

	UFUNCTION()
	void PreActivateElevatorLaser()
	{
		USkylineBallBossBigLaserEventHandler::Trigger_PreActivateElevatorLaser(this);
	}

	UFUNCTION()
	void ActivateLaser()
	{
		const bool bChaseLaserWasActive = bActive;
		bActive = true;
		bHadImpact = false;
		FadeTime = DefaultFadeTime;
		ProgressAlongSpline = 0.0;
		BallBoss.bHasSnapRotation = true;

		FSkylineBallBossAttackEventHandlerParams EventParams;
		EventParams.AttackType = ESkylineBallBossAttackEventHandlerType::LaserStart;
		USkylineBallBossEventHandler::Trigger_Attack(BallBoss, EventParams);
		
		if (OverrideLaserSpline != nullptr)
		{
			ActivateTelegraphLaser();
		}
		else if(!bChaseLaserWasActive)
		{
			ActivateChaseLaser();
		}	
	}

	private void ActivateChaseLaser()
	{
		LaserTrailComp.bSpawnDecals = true;
		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateOpen, ESkylineBallBossBlinkPriority::High);
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
		CollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		ScaleTarget = 1.0;

		OnLaserEnabled.Broadcast(true);

		LaserSpeedTimeLike.PlayFromStart();
		USkylineBallBossBigLaserEventHandler::Trigger_ActivateLaser(this);

	}

	private void ActivateTelegraphLaser()
	{
		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateSquint, ESkylineBallBossBlinkPriority::Med);

		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);

		if (OverrideLaserSpline.DelayedStartForRotationAlignment > KINDA_SMALL_NUMBER)
		{
			Timer::SetTimer(this, n"DelayedActivation", OverrideLaserSpline.DelayedStartForRotationAlignment);
		}
		else
		{
			TelegraphLaserMeshComp.SetVisibility(true);
			OverrideLaserSpline.LaserSpeedTimeLike.PlayFromStart();
			USkylineBallBossBigLaserEventHandler::Trigger_TelegraphLaser(this);
		}
	}

	private void ActivateRetraceLaser()
	{
		LaserTrailComp.bSpawnDecals = true;
		BallBoss.RemoveBlink(this);
		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateOpen, ESkylineBallBossBlinkPriority::High);

		ScaleTarget = 1.0;

		OnLaserEnabled.Broadcast(true);
		bHadImpact = false;

		USkylineBallBossBigLaserEventHandler::Trigger_ActivateLaser(this);
	}
	
	UFUNCTION()
	void DelayedActivation()
	{
		TelegraphLaserTrailComp.bSpawnDecals = true;
		TelegraphLaserMeshComp.SetVisibility(true);
		OverrideLaserSpline.LaserSpeedTimeLike.PlayFromStart();
		USkylineBallBossBigLaserEventHandler::Trigger_TelegraphLaser(this);
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		if (!bActive)
			return;

		// SetLaserFollowSpline(nullptr);
		LaserTrailComp.bSpawnDecals = false;
		bActive = false;
		ChaseOverlappedPlayers.Reset(2);
		ScaleTarget = 0.0;
		FadeTime = DefaultFadeTime;
		BallBoss.RemoveBlink(this);
		ImpactCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for (int i = 0; i < OverlappedResponders.Num(); ++i)
		{
			if (OverlappedResponders[i] != nullptr)
				OverlappedResponders[i].LaserOverlap(false);
		}
		OverlappedResponders.Reset();
		DeactivateLaserImpact();

		FSkylineBallBossAttackEventHandlerParams EventParams;
		EventParams.AttackType = ESkylineBallBossAttackEventHandlerType::LaserStop;
		USkylineBallBossEventHandler::Trigger_Attack(BallBoss, EventParams);

		USkylineBallBossBigLaserEventHandler::Trigger_DeactivateLaser(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (OverrideLaserSpline != nullptr && SkylineBallBossDevToggles::DrawLaser.IsEnabled())
			OverrideLaserSpline.Spline.DrawDebug();

		FVector ImpactLocation;
		FVector SplineLocation = FVector::ZeroVector;

		// FVector TargetLocation = ActorLocation + (SplineLocation - ActorLocation).GetSafeNormal() * 10000.0;
		// FVector AimLocation = Math::Lerp(BallBoss.AcceleratedTargetVector.Value, TargetLocation, LaserSpeedTimeLike.Position);

		if (GetSpline() != nullptr)
		{
			SplineLocation = GetSpline().GetWorldLocationAtSplineDistance(ProgressAlongSpline);
#if EDITOR
			if (BallBoss.DisableAttacksRequesters.Num() > 0)
			{
				auto RuntimeSpline = GetSpline().BuildRuntimeSplineFromHazeSpline();
				TEMPORAL_LOG(BallBoss, "LaserSpline").RuntimeSpline("Spliney", RuntimeSpline);
			}
#endif
		}
		LaserTrailComp.ProgressAlongSpline = ProgressAlongSpline;
		TelegraphLaserTrailComp.ProgressAlongSpline = ProgressAlongSpline;
		LaserTrailComp.SplineComponent = GetSpline();
		TelegraphLaserTrailComp.SplineComponent = GetSpline();

		// FVector TargetLocation = ActorLocation + (SplineLocation - ActorLocation).GetSafeNormal() * 10000.0;
		FVector TargetLocation = ActorLocation + (SplineLocation - ActorLocation).GetSafeNormal() * 10000.0;
		if (SplineLocation.Size() < KINDA_SMALL_NUMBER)
			BallBoss.bHasSnapRotation = false;
		FVector AimLocation = TargetLocation;
			
		// PrintToScreen("Alpha = " + LaserSpeedTimeLike.Position + " Forward = " + BallBossStartForward);

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.IgnorePlayers();
		Trace.IgnoreActor(BallBoss, true);

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, AimLocation);
		if (HitResult.bBlockingHit)
		{
			ImpactLocation = HitResult.ImpactPoint;
			// bool bShouldVFX = (OverrideLaserSpline == nullptr) || (OverrideLaserSpline != nullptr && OverrideLaserSpline.bRetrace && bRetracing);
			// float TempVFXScale = bShouldVFX ? 1.0 : 0.3;
			// LaserImpactVFXComp.SetWorldScale3D(FVector::OneVector * TempVFXScale);
			LaserImpactVFXComp.SetWorldRotation(FRotator::MakeFromXZ(ActorUpVector, HitResult.ImpactNormal));	
			TelegraphLaserImpactVFXComp.SetWorldRotation(FRotator::MakeFromXZ(ActorUpVector, HitResult.ImpactNormal));

			ActivateLaserImpact();

			ImpactCollisionComp.SetWorldLocation(ImpactLocation);
			if (SkylineBallBossDevToggles::DrawLaser.IsEnabled() && ImpactCollisionComp.GetCollisionEnabled() != ECollisionEnabled::NoCollision)
				Debug::DrawDebugSphere(ImpactCollisionComp.WorldLocation, ImpactCollisionComp.SphereRadius, 12, ColorDebug::Ruby);
		}
		else
		{
			// LaserImpactVFXComp.SetRelativeLocation(FVector::ZeroVector);
			LaserImpactVFXComp.SetWorldRotation(ActorRotation);
			ImpactLocation = AimLocation;
			DeactivateLaserImpact();

			if(bRetracing && bHadImpact)
				USkylineBallBossBigLaserEventHandler::Trigger_TraceLaserImpactEnd(this);
		}		

		bHadImpact = HitResult.bBlockingHit;

		AccLaserScale.AccelerateTo(ScaleTarget, FadeTime, DeltaSeconds);
		float LaserScaleXY = LaserXYScale * AccLaserScale.Value;
		float LaserScaleZ = LaserMeshComp.WorldLocation.Distance(ImpactLocation) / 1200;
		IrisOffset = TargetIrisOffset - AccLaserScale.Value * TargetIrisOffset;

		//Set telegraph laser scale
		TelegraphLaserMeshComp.SetWorldScale3D(FVector(0.05, 0.05, LaserScaleZ));

		if (LaserScaleXY > KINDA_SMALL_NUMBER && LaserScaleZ > KINDA_SMALL_NUMBER)
		{
			if (!LaserMeshComp.IsVisible())
			{
				LaserMeshComp.SetVisibility(true);		
			}

			LaserMeshComp.SetWorldScale3D(FVector(LaserScaleXY, LaserScaleXY, LaserScaleZ));
			SoulRootComp.SetRelativeLocation(FVector::UpVector * IrisOffset);
		}
		else
		{
			LaserMeshComp.SetVisibility(false);
			if (!bActive)
			{
				SetActorTickEnabled(false);
				OnLaserEnabled.Broadcast(false);
				BallBoss.bHasSnapRotation = false;
				DeactivateLaserImpact();
				USkylineBallBossBigLaserEventHandler::Trigger_DeactivateLaser(this);
			}
		}

		if (BallBoss != nullptr)
			BallBoss.SnapTargetLocation = AimLocation;

		for (int i = 0; i < ChaseOverlappedPlayers.Num(); ++i) 
		{
			AHazePlayerCharacter Player = ChaseOverlappedPlayers[i];
			if (Time::GetGameTimeSince(LastTimeHitPlayer[Player]) > ChaseLaserDamageCooldown)
			{
				Player.DamagePlayerHealth(ChaseLaserDamage, FPlayerDeathDamageParams(LaserMeshComp.UpVector, 2.0), BallBoss.LaserHeavyDamageEffect, BallBoss.LaserHeavyDeathEffect);
				LastTimeHitPlayer[Player] = Time::GameTimeSeconds;
				UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
				if (HealthComp.Health.CurrentHealth < KINDA_SMALL_NUMBER)
					Player.KillPlayer(FPlayerDeathDamageParams(LaserMeshComp.UpVector, 2.0), DeathEffect); // Combat Modifier option
			}	
		}

		if(LaserTrailComp.bSpawnDecals)
		{
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
			FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ImpactCollisionComp.WorldLocation, 1000, 2000);
		}
	}

	private void ActivateLaserImpact()
	{
		if (LaserMeshComp.bVisible)
			LaserImpactVFXComp.Activate();
		if (TelegraphLaserMeshComp.bVisible)
			TelegraphLaserImpactVFXComp.Activate();
	}

	private void DeactivateLaserImpact()
	{
		LaserImpactVFXComp.Deactivate();
		TelegraphLaserImpactVFXComp.Deactivate();
	}

	void SetLaserFollowSpline(ASkylineBallBossTopLaserSpline LaserSpline)
	{
		OverrideLaserSpline = LaserSpline;
		if (OverrideLaserSpline == nullptr)
			return;
		OverrideLaserSpline.LaserSpeedTimeLike.BindUpdate(this, n"LaserSpeedTimeLikekeUpdate");
		OverrideLaserSpline.LaserSpeedTimeLike.BindFinished(this, n"LaserSpeedTimeLikeFinished");
		OverrideLaserSpline.RetraceLaserSpeedTimeLike.BindUpdate(this, n"LaserSpeedTimeLikekeUpdate");
		OverrideLaserSpline.RetraceLaserSpeedTimeLike.BindFinished(this, n"LaserRetraceSpeedTimeLikeFinished");
	}

	float GetLaserDuration()
	{
		if (OverrideLaserSpline != nullptr)
			return OverrideLaserSpline.LaserSpeedTimeLike.Duration + OverrideLaserSpline.RetraceLaserSpeedTimeLike.Duration + OverrideLaserSpline.DelayedStartForRotationAlignment;
		return LaserSpeedTimeLike.Duration;
	}

	private bool ShouldRetrace()
	{
		return OverrideLaserSpline != nullptr && OverrideLaserSpline.bRetrace;
	}

	private UHazeSplineComponent GetSpline()
	{
		if (OverrideLaserSpline != nullptr)
			return OverrideLaserSpline.Spline;
		return nullptr;
	}
};