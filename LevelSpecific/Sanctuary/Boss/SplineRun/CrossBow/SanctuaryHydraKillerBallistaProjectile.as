event void FHydraKillerProjectileHitSignature();

class ASanctuaryHydraKillerBallistaProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CompanionRotateRoot;

	UPROPERTY(DefaultComponent, Attach = CompanionRotateRoot)
	USceneComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent, Attach = CompanionRotateRoot)
	USceneComponent LightBirdTargetComp;

	UPROPERTY()
	FHazeTimeLike DarkPortalTargetSpinTimeLike;
	default DarkPortalTargetSpinTimeLike.Duration = 1.0;
	default DarkPortalTargetSpinTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityTrackerComp;

	UPROPERTY()
	FDarkPortalInvestigationDestination DarkPortalInvestigationDestination;

	UPROPERTY()
	FLightBirdInvestigationDestination LightBirdInvestigationDestination;

	UPROPERTY(EditInstanceOnly)
	EMedallionHydra MedallionTargetHydraType;
	ASanctuaryBossMedallionHydra MedallionTargetHydra;

	UPROPERTY(DefaultComponent)
	USceneComponent BladePivot;

	UPROPERTY(DefaultComponent)
	USceneComponent BladeRotatePivot1;

	UPROPERTY(DefaultComponent)
	USceneComponent BladeRotatePivot2;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 16000.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryHydraKillerBallista Ballista;

	UPROPERTY(EditInstanceOnly)
	AHazeActor AlternativeTarget;

	UPROPERTY()
	float HomingDuration = 1.0;

	UPROPERTY()
	FHazeTimeLike HomingTimeLike;
	default HomingTimeLike.UseLinearCurveZeroToOne();
	default HomingTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeTimeLike BladeTimeLike;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve HeightCurve;

	UPROPERTY(EditAnywhere)
	float NotIndusedFlyDistance = 20000.0;

	UPROPERTY(EditAnywhere)
	float NotInfusedFlyHeight = 7000.0;

	UPROPERTY(EditAnywhere)
	float NotInfusedFlyDuration = 4.0;

	UPROPERTY()
	FHydraKillerProjectileHitSignature OnHit;

	UPROPERTY()
	FHydraKillerProjectileHitSignature OnStartHit;

	//Cut throat stuff
	const float HydraNeckRadius = 1800.0;
	const float HydraNeckAddedArrowPathRadius = 1900.0;
	const float TimeDilationMultiplier = 0.2;
	const float CutHeadDuration = 0.3;
	FVector RelativeArrowDirection;

	const float BackwardsDistance = 650.0;

	float Velocity;
	bool bFired = false;
	bool bInfused = false;
	bool bHasCompanions = false;
	float CompanionRotAroundInfused = 0.0;

	FVector InitialForward;
	FVector InitialLocation;
	float DownwardsVelocity = 0.0;
	FVector DefaultScale;
	float HomingMultiplier = 0.0;
	UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultScale = BladePivot.RelativeScale3D;
		DarkPortalInvestigationDestination.TargetComp = DarkPortalTargetComp;
		LightBirdInvestigationDestination.TargetComp = LightBirdTargetComp;

		if(Ballista!=nullptr)
		{
			Ballista.OnMashCompleted.AddUFunction(this, n"HandleMashCompleted");
		}

		DarkPortalTargetSpinTimeLike.BindUpdate(this, n"DarkPortalTargetSpinTimeLikeUpdate");
		DarkPortalTargetSpinTimeLike.BindFinished(this, n"DarkPortalTargetSpinTimeLikeFinished");

		HomingTimeLike.BindUpdate(this, n"HomingTimeLikeUpdate");
		BladeTimeLike.BindUpdate(this, n"BladeTimeLikeUpdate");
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (EndPlayReason == EEndPlayReason::EndPlayInEditor)
			return;
		if (bHasCompanions)
			CompanionsStopInvestigate();
	}

	UFUNCTION(BlueprintPure)
	USceneComponent GetTargetComp() const 
	{
		auto LocalMedallionTargetHydra = RefsComp.Refs.GetHydraByEnum(MedallionTargetHydraType);
		if (LocalMedallionTargetHydra != nullptr)
			return LocalMedallionTargetHydra.TargetComp;
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFired)
		{
			if (bInfused)
			{
				FTransform CutoffBoneTransform = MedallionTargetHydra.GetCutBoneTransform();
				FVector HomingMovement = (CutoffBoneTransform.Location - ActorLocation).GetSafeNormal();
				FVector Direction = Math::Lerp(InitialForward, HomingMovement, HomingMultiplier);
				FVector DeltaMove = Direction.GetSafeNormal() * Velocity * DeltaSeconds;
				float MaxMove = ActorLocation.Distance(CutoffBoneTransform.Location) - HydraNeckRadius;
				if (DeltaMove.Size() >= MaxMove)
				{
					DeltaMove = DeltaMove.GetSafeNormal() * MaxMove;
					StartHitTarget();
				}
				AddActorWorldOffset(DeltaMove);	
				SetActorRotation(VelocityTrackerComp.GetCurrentFrameDeltaTranslation().Rotation());
				const float MaxVelocity = 100;
				const float SlowDegrees = 1;
				const float FastDegrees = 360.0 * 3.0;
				float DeltaAddedRot = Math::GetMappedRangeValueClamped(FVector2D(0.0, MaxVelocity), FVector2D(SlowDegrees, FastDegrees), Math::Clamp(Velocity, 0.0, MaxVelocity));
				CompanionRotAroundInfused += DeltaAddedRot * DeltaSeconds;
				CompanionRotateRoot.SetRelativeRotation(FRotator(0.0, 0.0, CompanionRotAroundInfused));
			}
			else
			{
				//DownwardsVelocity += 2000.0 * DeltaSeconds;
				//AddActorWorldOffset((InitialForward * Velocity + FVector::DownVector * DownwardsVelocity) * DeltaSeconds);
			}

		}
	}

	void StartHitTarget()
	{
		bFired = false;

		FTimeDilationEffect TimeDilationEffect;
		TimeDilationEffect.TimeDilation = 0.2;
		TimeDilationEffect.BlendInDurationInRealTime = 0.0;
		TimeDilationEffect.BlendOutDurationInRealTime = 0.0;
	//	TimeDilation::StartWorldTimeDilationEffect(TimeDilationEffect, this);

		//Time::SetWorldTimeDilation(TimeDilationMultiplier);
		//AttachToComponent(MedallionTargetHydra.TargetComp, NAME_None, EAttachmentRule::KeepWorld);

		RelativeArrowDirection = -ActorRelativeLocation.GetSafeNormal();
		SetActorRelativeRotation(FRotator::MakeFromXY(RelativeArrowDirection, MedallionTargetHydra.TargetComp.RightVector));

		//BP_StartBlood();

		OnStartHit.Broadcast();

		MedallionTargetHydra.StartBallistaKillSequence();
		// MedallionTargetHydra.OneshotAnimation(EFeatureTagMedallionHydra::Death, 1.5);
		
		SetActorHiddenInGame(true);

		QueueComp.Empty();
	//	QueueComp.Duration(CutHeadDuration, this, n"CutHydraUpdate");
		QueueComp.Idle(CutHeadDuration);
		QueueComp.Event(this, n"HydraHeadCut");
	}

	UFUNCTION()
	private void CutHydraUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(-1.0, 0.0, Alpha, 2.0);
		SetActorRelativeLocation(RelativeArrowDirection * (HydraNeckRadius + HydraNeckAddedArrowPathRadius) * CurrentValue);

		MedallionTargetHydra.SkeletalMesh.SetVectorParameterValueOnMaterials(n"ArrowLocation", GetActorLocation());
		MedallionTargetHydra.SkeletalMesh.SetVectorParameterValueOnMaterials(n"ArrowForwardDirection", GetActorForwardVector());
		MedallionTargetHydra.SkeletalMesh.SetVectorParameterValueOnMaterials(n"ArrowUpDirection", GetActorUpVector());
	}

	UFUNCTION()
	private void HydraHeadCut()
	{
		TimeDilation::StopWorldTimeDilationEffect(this);
		HitTarget();

		BP_StopBlood();
	}

	void Infuse()
	{
		if (bInfused)
			return;

		Timer::SetTimer(this, n"DelayedInfuse", 0.5);
		bInfused = true;
		CompanionRotAroundInfused = CompanionRotateRoot.RelativeRotation.Yaw;
	}

	FVector GetTargetLocation()
	{
		return GetTargetComp().WorldLocation;
	}

	UFUNCTION()
	private void DelayedInfuse()
	{
		DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination, this);
		LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination, this);
		bHasCompanions = true;
		DarkPortalTargetSpinTimeLike.Play();

		BP_Infuse();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Infuse(){}

	UFUNCTION(BlueprintEvent)
	void BP_Infused(){}

	UFUNCTION(BlueprintEvent)
	void BP_BladeActivated(){}

	UFUNCTION()
	private void DarkPortalTargetSpinTimeLikeUpdate(float CurrentValue)
	{
		CompanionRotateRoot.SetRelativeLocation(FVector::ForwardVector * 700.0 * CurrentValue);
		CompanionRotateRoot.SetRelativeRotation(FRotator(0.0, 0.0, 720.0 * CurrentValue));
	}

	UFUNCTION()
	private void DarkPortalTargetSpinTimeLikeFinished()
	{
		BP_Infused();
	}

	void Fire(float SetVelocity)
	{
		Velocity = bInfused ? SetVelocity * 1.5 : SetVelocity;
		bFired = true;

		InitialForward = ActorForwardVector;
		InitialLocation = ActorLocation;

		//HomingTimeLike.Play();
		if (bInfused)
			QueueComp.Duration(0.5, this, n"HomingUpdate");
		else
		{
			QueueComp.Duration(NotInfusedFlyDuration, this, n"UnInfusedArrowFire");
			QueueComp.Event(this, n"BallistaFlyFinished");
		}
	}

	UFUNCTION()
	private void UnInfusedArrowFire(float Alpha)
	{
		
		FVector Location = GetArrowLocation(Alpha);
		FVector Direction = (GetArrowLocation(Alpha + KINDA_SMALL_NUMBER) - GetArrowLocation(Alpha - KINDA_SMALL_NUMBER)).GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromXZ(Direction, FVector::UpVector);
		SetActorLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	private void BallistaFlyFinished()
	{
		AddActorDisable(this);
	}

	private FVector GetArrowLocation(float Alpha)
	{
		FVector ForwardDirection = FRotator::MakeFromZX(FVector::UpVector, InitialForward).ForwardVector;
		FVector ForwardOffset = ForwardDirection * NotIndusedFlyDistance * Alpha;
		FVector UpwardOffset = FVector::UpVector * (HeightCurve.GetFloatValue(Alpha) * NotInfusedFlyHeight);
		FVector Location = InitialLocation;
		Location += ForwardOffset;
		Location += UpwardOffset;

		return Location;
	}

	UFUNCTION()
	private void HomingUpdate(float Alpha)
	{
		HomingMultiplier = Alpha;
	}

	UFUNCTION()
	private void HomingTimeLikeUpdate(float CurrentValue)
	{
		HomingMultiplier = CurrentValue;
	}

	UFUNCTION()
	private void HandleMashCompleted()
	{
		if (RefsComp.Refs != nullptr)
		{
			MedallionTargetHydra = RefsComp.Refs.GetHydraByEnum(MedallionTargetHydraType);
			MedallionTargetHydra.bIsBallistaAttacked = true;
			MedallionTargetHydra.StartAggroInbeforeDying();
		}

		QueueComp.Idle(1.0);
		QueueComp.Event(this, n"BP_BladeActivated");
		QueueComp.Duration(0.2, this, n"BladeExtendUpdate");
		QueueComp.Event(this, n"BladeExtended");
	}

	UFUNCTION()
	private void BladeExtendUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 2.0);
		float RotationValue = Math::Lerp(0.0, 80.0, CurrentValue);
		BladeRotatePivot1.SetRelativeRotation(FRotator(0.0, RotationValue, 0.0));
		BladeRotatePivot2.SetRelativeRotation(FRotator(0.0, -RotationValue, 0.0));
	}

	UFUNCTION()
	private void BladeExtended()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void BladeTimeLikeUpdate(float CurrentValue)
	{
		BladePivot.RelativeScale3D = FVector(1.0, CurrentValue * 20, CurrentValue * 20);

		float RotationValue = Math::Lerp(0.0, 80.0, CurrentValue);
		BladeRotatePivot1.SetRelativeRotation(FRotator(0.0, RotationValue, 0.0));
		BladeRotatePivot2.SetRelativeRotation(FRotator(0.0, -RotationValue, 0.0));
	}

	private void HitTarget()
	{
		bInfused = false;
		bFired = false;
		InitialForward = ActorForwardVector;

		BP_HitTarget();
		// if (TargetHydra != nullptr)
		// {
		// 	TargetHydra.HitByArrow();
		// }
		// else

		MedallionTargetHydra.HitByArrow();


		CompanionsStopInvestigate();
		OnHit.Broadcast();

		QueueComp.Idle(2.0);
		QueueComp.Event(this, n"DelayedDisable");
	}

	UFUNCTION()
	private void DelayedDisable()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_HitTarget(){}

	UFUNCTION()
	void CompanionsStopInvestigate()
	{
		if (!bHasCompanions)
			return;
		DarkPortalCompanion::DarkPortalStopInvestigating(this);
		LightBirdCompanion::LightBirdStopInvestigating(this);
		bHasCompanions = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartBlood(){}

	UFUNCTION(BlueprintEvent)
	void BP_StopBlood(){}
};