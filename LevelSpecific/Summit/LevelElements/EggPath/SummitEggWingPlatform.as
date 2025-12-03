event void FSummitEggWingPlatformSignature();

class ASummitEggWingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent RightPivot;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent LeftPivot;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent EndPositionComp;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent LeftEndPositionComp;

	FRotator RotationRate = FRotator(0,-15, 0); 

	UPROPERTY(EditAnywhere)
	ASummitEggHolder EggHolder;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder LockEggHolder;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder RotationEggHolder;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	FTransform LeftStartingTransform;
	FQuat LeftStartingRotation;
	FVector LeftStartingPosition;
	FTransform LeftEndingTransform;
	FQuat LeftEndingRotation;
	FVector LeftEndingPosition;

	bool bIsPlaying;
	bool bWingsUp;
	bool bLocked;
	bool bEggIsPlaced;
	bool bCanRotate;

	UPROPERTY()
	FSummitEggWingPlatformSignature OnMoving;

	UPROPERTY(EditAnywhere)
	AKineticRotatingActor RotatingActorRef;

	UPROPERTY(EditAnywhere)
	bool bShouldRotate = true;
	float RotationSpeed = 15.0;
	FHazeAcceleratedFloat AccelRotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = RightPivot.GetRelativeTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndPositionComp.GetRelativeTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		LeftStartingTransform = LeftPivot.GetRelativeTransform();
		LeftStartingPosition = LeftStartingTransform.GetLocation();
		LeftStartingRotation = LeftStartingTransform.GetRotation();

		LeftEndingTransform = LeftEndPositionComp.GetRelativeTransform();
		LeftEndingPosition = LeftEndingTransform.GetLocation();
		LeftEndingRotation = LeftEndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (EggHolder != nullptr)
		{
			EggHolder.OnEggPlaced.AddUFunction(this, n"EggIsPlaced");
			EggHolder.OnEggRemoved.AddUFunction(this, n"EggIsRemoved");
		}

		if (LockEggHolder != nullptr)
		{
			LockEggHolder.OnEggPlaced.AddUFunction(this, n"LockEggIsPlaced");
			LockEggHolder.OnEggRemoved.AddUFunction(this, n"LockEggIsRemoved");
		}

		if (bShouldRotate)
		{
			RotationEggHolder.OnEggPlaced.AddUFunction(this, n"RotationEggIsPlaced");
			RotationEggHolder.OnEggRemoved.AddUFunction(this, n"RotationEggIsRemoved");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCanRotate)
			AccelRotationSpeed.AccelerateTo(RotationSpeed, 0.75, DeltaSeconds);
		else
			AccelRotationSpeed.AccelerateTo(0.0, 0.75, DeltaSeconds);
		
		Root.AddLocalRotation(FRotator(0,AccelRotationSpeed.Value,0) * DeltaSeconds);
	}

	UFUNCTION()
	void EggIsPlaced()
	{
		bEggIsPlaced = true;

		if (bLocked)
			return;

		MoveAnimation.Play();
		
		if (MoveAnimation.GetValue() >= 1)
			return;

		UASummitEggWingPlatformEffectHandler::Trigger_WingsUp(this);
		// PrintToScreen("WingsUp", 1);
	}
	
	UFUNCTION()
	void EggIsRemoved()
	{
		bEggIsPlaced = false;

		if (!bLocked && !bEggIsPlaced)
		{
			MoveAnimation.Reverse(); 
			UASummitEggWingPlatformEffectHandler::Trigger_WingsDown(this);
			// PrintToScreen("WingsDown", 1);
		}
	}

	UFUNCTION()
	void LockEggIsPlaced()
	{
		bLocked = true;

		if (bEggIsPlaced)
			return;

		MoveAnimation.Play();

		if (MoveAnimation.GetValue() >= 1)
			return;

		UASummitEggWingPlatformEffectHandler::Trigger_WingsUp(this);
		// PrintToScreen("WingsUp", 1);


	}
	
	UFUNCTION()
	void LockEggIsRemoved()
	{
		bLocked = false;
		
		if (!bLocked && !bEggIsPlaced)
		{
			MoveAnimation.Reverse();  
			UASummitEggWingPlatformEffectHandler::Trigger_WingsDown(this);
			// PrintToScreen("WingsDown", 1);

		}
	}

	UFUNCTION()
	void RotationEggIsPlaced()
	{
		bCanRotate = true;
		UASummitEggWingPlatformEffectHandler::Trigger_StartTurning(this);
	}
	
	UFUNCTION()
	void RotationEggIsRemoved()
	{
		bCanRotate = false;
		UASummitEggWingPlatformEffectHandler::Trigger_StopTurning(this);
	}

	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		// RightPivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		// RightPivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		// LeftPivot.SetWorldLocation(Math::Lerp(LeftStartingPosition, LeftEndingPosition, Alpha));
		// LeftPivot.SetWorldRotation(FQuat::SlerpFullPath(LeftStartingRotation, LeftEndingRotation, Alpha));

		RightPivot.SetRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		LeftPivot.SetRelativeRotation(FQuat::SlerpFullPath(LeftStartingRotation, LeftEndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		if (MoveAnimation.IsReversed())
		{
			bWingsUp = false; 
			UASummitEggWingPlatformEffectHandler::Trigger_WingsFullyDown(this);

		}
		else
		{
			bWingsUp = true; 
			UASummitEggWingPlatformEffectHandler::Trigger_WingsFullyUp(this);
		}
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsPlaced() {}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsRemoved() {}

};

UCLASS(Abstract)
class UASummitEggWingPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingsUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingsDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingsFullyUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingsFullyDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartTurning() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopTurning() {}
}