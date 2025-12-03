class AOilRigPump : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent LeftBase;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent RightBase;

	UPROPERTY(DefaultComponent, Attach = LeftBase)
	USceneComponent LeftPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = LeftPlatformRoot)
	USceneComponent LeftRamp;

	UPROPERTY(DefaultComponent, Attach = LeftPlatformRoot)
	USceneComponent LeftHinge;

	UPROPERTY(DefaultComponent, Attach = RightBase)
	USceneComponent RightPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = RightPlatformRoot)
	USceneComponent RightRamp;

	UPROPERTY(DefaultComponent, Attach = RightPlatformRoot)
	USceneComponent RightHinge;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent FFOriginComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve PumpCurve;
	UPROPERTY(EditAnywhere)
	float PumpDuration = 2.5;
	UPROPERTY(EditAnywhere)
	float StartOffset = 0.0;

	bool bReachedStart = false;
	bool bReachedEnd = false;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve FFCurve;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float Roll = ActorRotation.Roll;
		FVector DirLeftRight = (RightHinge.WorldLocation - LeftHinge.WorldLocation).GetSafeNormal();
		FRotator LeftRot = DirLeftRight.Rotation();
		LeftRot.Roll = Roll;
		LeftHinge.SetWorldRotation(LeftRot);

		FVector DirRightToLeft = (LeftHinge.WorldLocation - RightHinge.WorldLocation).GetSafeNormal();
		FRotator RightRot = DirRightToLeft.Rotation();
		RightRot.Roll = -Roll;
		RightHinge.SetWorldRotation(RightRot);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> PlatformRoots;
		PlatformRoots.Add(LeftPlatformRoot);
		PlatformRoots.Add(RightPlatformRoot);

		for (USceneComponent PlatformRoot : PlatformRoots)
		{
			FRotator OriginalRotation = PlatformRoot.WorldRotation;
			PlatformRoot.SetAbsolute(false, true, false);
			PlatformRoot.SetWorldRotation(OriginalRotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurTime = (Time::PredictedGlobalCrumbTrailTime + StartOffset) / PumpDuration;
		float WrappedTime = Math::Wrap(CurTime, 0.0, 2.0);
		if (WrappedTime > 1.0)
			WrappedTime = 2.0 - WrappedTime;
		float CurValue = PumpCurve.GetFloatValue(WrappedTime);


		if (!bReachedStart && Math::IsNearlyEqual(CurValue, 0.0, 0.02))
		{
			bReachedStart = true;
			bReachedEnd = false;
			UOilRigPumpEffectEventHandler::Trigger_ReachedBottom(this);
		}
		if (!bReachedEnd && Math::IsNearlyEqual(CurValue, 1.0, 0.02))
		{
			bReachedStart = false;
			bReachedEnd = true;
			UOilRigPumpEffectEventHandler::Trigger_ReachedTop(this);
		}

		float LeftOffset = Math::Lerp(1750.0, 2250.0, CurValue);
		LeftPlatformRoot.SetRelativeLocation(FVector(0.0, 0.0, LeftOffset));
		float RightOffset = Math::Lerp(2250.0, 1750.0, CurValue);
		RightPlatformRoot.SetRelativeLocation(FVector(0.0, 0.0, RightOffset));

		float Roll = ActorRotation.Roll;
		FVector DirLeftRight = (RightHinge.WorldLocation - LeftHinge.WorldLocation).GetSafeNormal();
		FRotator LeftRot = DirLeftRight.Rotation();
		LeftRot.Roll = Roll;
		LeftHinge.SetWorldRotation(LeftRot);

		FVector DirRightToLeft = (LeftHinge.WorldLocation - RightHinge.WorldLocation).GetSafeNormal();
		FRotator RightRot = DirRightToLeft.Rotation();
		RightRot.Roll = -Roll;
		RightHinge.SetWorldRotation(RightRot);

		float RightRampRot = Math::Lerp(26.0, 0.0, CurValue);
		RightRamp.SetRelativeRotation(FRotator(RightRampRot, 0.0, 0.0));
		float LeftRampRot = Math::Lerp(0.0, 20.0, CurValue);
		LeftRamp.SetRelativeRotation(FRotator(LeftRampRot, 180.0, 0.0));

		float FFValue = FFCurve.GetFloatValue(WrappedTime) * 0.5;
		FHazeFrameForceFeedback FrameFF;
		FrameFF.LeftMotor = bReachedStart ? 0.0 : FFValue * (Math::Sin(Time::GameTimeSeconds * 60.0));
		FrameFF.RightMotor = bReachedStart ? FFValue * (Math::Sin(-Time::GameTimeSeconds * 60.0)) : 0.0;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FrameFF, FFOriginComp.WorldLocation, 1000.0, 600.0);
	}
}

class UOilRigPumpEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ReachedTop() {}
	UFUNCTION(BlueprintEvent)
	void ReachedBottom() {}
}