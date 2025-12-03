class ASanctuaryBossMedallionHydraTransformActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(EditAnywhere)
	TArray<EMedallionPhase> Phases;

	UPROPERTY(EditAnywhere)
	EMedallionHydra Hydra = EMedallionHydra::MioLeft;

	UPROPERTY(EditAnywhere)
	EMedallionHydraMovePivotPriority Priority = EMedallionHydraMovePivotPriority::Medium;

	UPROPERTY(EditAnywhere)
	bool bFlyingHydra = false;

	UPROPERTY(EditAnywhere, meta = (EditCondition="bSlashLaserHydra", EditConditionHides))
	FVector2D StartLaserPlaneLocation;

	UPROPERTY(EditAnywhere, meta = (EditCondition="bSlashLaserHydra", EditConditionHides))
	FVector2D EndLaserPlaneLocation;

	FVector2D AverageLaserRelativeLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UGodrayComponent TelegraphGodRay;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent AttackQueueComp;

	ASanctuaryBossMedallionHydraReferences Refs;
	ASanctuaryBossMedallionHydra HydraActor;
	FTransform StartTransform;

	FRotator TargetRotation;

	FQuat BaseHeadRelativeRotation;
	FVector BaseHeadForward;
	FVector HeadRootRelativeLocation;

	UPROPERTY(EditAnywhere)
	float LerpDuration = 2.0;

	UPROPERTY(EditAnywhere)
	bool bLookAtPlayer = true;

	private bool bApplying = false;

	private bool bLaserAttacking = false;

	FHazeAcceleratedRotator AccHeadRot;
	AHazePlayerCharacter ClosestPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseHeadForward = HeadRoot.ForwardVector;
		TargetRotation = HeadRoot.WorldRotation;
		BaseHeadRelativeRotation = HeadRoot.RelativeRotation.Quaternion();
		HeadRootRelativeLocation = ActorTransform.InverseTransformPositionNoScale(HeadRoot.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (EndPlayReason == EEndPlayReason::Destroyed || EndPlayReason == EEndPlayReason::RemovedFromWorld)
			DeactivateTransformHydra();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Refs == nullptr)
		{
			CacheRefs();
			return;
		}

		if (HydraActor == nullptr)
			return;

		if (!bApplying)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (bLookAtPlayer)
			LookAtPlayerAndBite(DeltaSeconds);
	}

	private void LookAtPlayerAndBite(float DeltaSeconds)
	{
		ClosestPlayer = 
			Game::Mio.ActorLocation.Distance(HeadRoot.WorldLocation) <
			Game::Zoe.ActorLocation.Distance(HeadRoot.WorldLocation) ?
			Game::Mio :
			Game::Zoe;

		FRotator LookAtPlayerRotation = (ClosestPlayer.Mesh.GetBoneTransform(n"Hips").Location - HeadRoot.WorldLocation).GetSafeNormal().Rotation();
		bool bIsInFlying = bFlyingHydra && !bLaserAttacking && Refs.IsInFlyingPhase(false, false, false);
		TargetRotation = LookAtPlayerRotation;

		float LookAtPlayerAlpha = 1.0;
		if (bIsInFlying)
			LookAtPlayerAlpha = GetSpecialCaseFlyingAlpha();
		if (LookAtPlayerAlpha < 1.0 - KINDA_SMALL_NUMBER)
			TargetRotation = FQuat::Slerp(GetHeadBaseRotation(), LookAtPlayerRotation.Quaternion(), LookAtPlayerAlpha).Rotator();
		
		if (SanctuaryMedallionHydraDevToggles::Draw::HydraHeadPivot.IsEnabled())
			Debug::DrawDebugString(HeadRoot.WorldLocation, "Look At player alpha " + LookAtPlayerAlpha, ColorDebug::White, 0.0, 2.5);

		AccHeadRot.AccelerateTo(TargetRotation, 1.0, DeltaSeconds);

		if (!bLaserAttacking)
			HeadRoot.SetWorldRotation(AccHeadRot.Value);
	}

	float GetSpecialCaseFlyingAlpha()
	{
		ASanctuaryBossMedallionSpline FlyingSpline =  Refs.MedallionBossPlane2D.GetFlyingSpline();
		// distance along spline?
		float HydraSplineDistance = FlyingSpline.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		float SplineDistanceDifference = Math::Clamp(HydraSplineDistance -  Refs.MedallionBossPlane2D.AccSplineDistance.Value, 0.0, FlyingSpline.Spline.SplineLength);
		
		float AlphaByDistance = Math::GetMappedRangeValueClamped(
			MedallionConstants::Flying::HydraLookAtPlayerMaxMinSplineDistance, 
			FVector2D(1.0, 0.0), SplineDistanceDifference);

		// if (SanctuaryMedallionHydraDevToggles::Draw::HydraHeadPivot.IsEnabled())
		// 	Debug::DrawDebugString(HeadRoot.WorldLocation, "\n\n\n Dist: " + SplineDistanceDifference, Scale = 3.0, Color = Math::Lerp(ColorDebug::Black, ColorDebug::Green, AlphaByDistance));

		return AlphaByDistance;
	}

	FQuat GetHeadBaseRotation()
	{
		return FQuat::ApplyRelative(ActorQuat, BaseHeadRelativeRotation);
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase NewPhase, bool bNaturalProgression)
	{
		if (HydraActor == nullptr)
			return;
		if (HydraActor.bIsControlledByCutscene)
			return;
		bool bHasPhase = false;

		for (EMedallionPhase Phase : Phases)
		{
			if (NewPhase == Phase)
			{
				bHasPhase = true;
				break;
			}
		}

		if (bHasPhase)
			RequestTransformHydra(false);
		else
			DeactivateTransformHydra();
	}

	private void RequestTransformHydra(bool bSnap)
	{
		if (bApplying)
			return;
		bApplying = true;
		HydraActor.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, Priority, LerpDuration, bSnap);
		HydraActor.MoveActorComp.ApplyTransform(this, Root, Priority, LerpDuration, bSnap, false);

		if (bFlyingHydra)
			HydraActor.OnFlyingLaserActivated.AddUFunction(this, n"HandleFlyingLaserActivated");

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateTransformHydra()
	{
		if (!bApplying)
			return;
		bApplying = false;
		HydraActor.MoveActorComp.Clear(this);
		HydraActor.MoveHeadPivotComp.Clear(this);

		if (bFlyingHydra)
			HydraActor.OnFlyingLaserActivated.UnbindObject(this);
	}

	UFUNCTION()
	private void HandleFlyingLaserActivated()
	{
		SetupTelegraphTransform();

		bLaserAttacking = true;
		HydraActor.EnterMhAnimation(EFeatureTagMedallionHydra::Roar);
		HydraActor.ActivateLaser(1.5, LaserType = EMedallionHydraLaserType::FlyingDownwardsSweep);
		AttackQueueComp.Duration(2.0, this, n"TelegraphLaser");
		AttackQueueComp.Duration(1.0, this, n"SlashLaser");
		AttackQueueComp.Event(this, n"LaserFinished");
		AttackQueueComp.Duration(1.0, this, n"ReturnHead");
		AttackQueueComp.Event(this, n"ReturnToRegularTargeting");
	}

	private void SetupTelegraphTransform()
	{
		AverageLaserRelativeLocation = (StartLaserPlaneLocation + EndLaserPlaneLocation) * 0.5;
		TelegraphRoot.SetWorldLocation(Refs.MedallionBossPlane2D.ActorTransform.TransformPositionNoScale(FVector(0.0, AverageLaserRelativeLocation.X, AverageLaserRelativeLocation.Y)));
		TelegraphRoot.AttachToComponent(Refs.MedallionBossPlane2D.Root, NAME_None, EAttachmentRule::KeepWorld);

		FRotator TelegraphRotation = (
			FVector(0.0, EndLaserPlaneLocation.X, EndLaserPlaneLocation.Y) 
			- FVector(0.0, StartLaserPlaneLocation.X, StartLaserPlaneLocation.Y))
			.GetSafeNormal()
			.Rotation();
		
		TelegraphRoot.SetRelativeRotation(TelegraphRotation);
	}

	UFUNCTION()
	private void TelegraphLaser(float Alpha)
	{
		float CurrentValue = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);

		FVector LaserStartLocation = Refs.MedallionBossPlane2D.ActorTransform.TransformPositionNoScale(FVector(0.0, StartLaserPlaneLocation.X, StartLaserPlaneLocation.Y));
		FVector LaserStartForward = (LaserStartLocation - HeadRoot.WorldLocation).GetSafeNormal();
		FRotator LaserStartRotation = FRotator::MakeFromXZ(LaserStartForward, FVector::UpVector);

		FRotator LerpedRotation = Math::LerpShortestPath(TargetRotation, LaserStartRotation, CurrentValue);
		HeadRoot.SetWorldRotation(LerpedRotation);

		TelegraphGodRay.SetGodrayOpacity(Alpha * 0.6);
	}

	UFUNCTION()
	private void SlashLaser(float Alpha)
	{
		float CurrentValue = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);

		FVector LaserStartLocation = Refs.MedallionBossPlane2D.ActorTransform.TransformPositionNoScale(FVector(0.0, StartLaserPlaneLocation.X, StartLaserPlaneLocation.Y));
		FVector LaserStartForward = (LaserStartLocation - HeadRoot.WorldLocation).GetSafeNormal();
	
		FVector LaserEndLocation = Refs.MedallionBossPlane2D.ActorTransform.TransformPositionNoScale(FVector(0.0, EndLaserPlaneLocation.X, EndLaserPlaneLocation.Y));
		FVector LaserEndForward = (LaserEndLocation - HeadRoot.WorldLocation).GetSafeNormal();
		
		FVector LerpedTargetLocation = Math::Lerp(LaserStartLocation, LaserEndLocation, CurrentValue);
		FVector LerpedForward = (LerpedTargetLocation - HeadRoot.WorldLocation).GetSafeNormal();
		FRotator LaserRotation = FRotator::MakeFromXZ(LerpedForward, FVector::UpVector);

		HeadRoot.SetWorldRotation(LaserRotation);

		TelegraphGodRay.SetGodrayOpacity(1 - Alpha);
	}

	UFUNCTION()
	private void LaserFinished()
	{
		HydraActor.DeactivateLaser();
		HydraActor.ExitMhAnimation(EFeatureTagMedallionHydra::Roar);
	}
	
	UFUNCTION()
	private void ReturnHead(float Alpha)
	{
		float CurrentValue = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);

		FVector LaserEndLocation = Refs.MedallionBossPlane2D.ActorTransform.TransformPositionNoScale(FVector(0.0, EndLaserPlaneLocation.X, EndLaserPlaneLocation.Y));
		FVector LaserEndForward = (LaserEndLocation - HeadRoot.WorldLocation).GetSafeNormal();
		FRotator LaserEndRotation = FRotator::MakeFromXZ(LaserEndForward, FVector::UpVector);

		FRotator LerpedRotation = Math::LerpShortestPath(LaserEndRotation, TargetRotation, CurrentValue);
		HeadRoot.SetWorldRotation(LerpedRotation);
	}

	UFUNCTION()
	private void ReturnToRegularTargeting()
	{
		bLaserAttacking = false;
	}

	private void CacheRefs()
	{
		TListedActors<ASanctuaryBossMedallionHydraReferences> ListedRefs;
		Refs = ListedRefs.Single;

		if (Refs != nullptr)
		{
			SetupReferences();
		}
	}

	private void SetupReferences()
	{
		Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
			
		for (ASanctuaryBossMedallionHydra RefHydra : Refs.Hydras)
		{
			if (RefHydra.HydraType == Hydra)
			{
				HydraActor = RefHydra;
				break;
			}
		}

		for (EMedallionPhase Phase : Phases)
		{
			if (Refs.HydraAttackManager.Phase == Phase)
			{
				RequestTransformHydra(true);
				break;
			}
		}
	}
};