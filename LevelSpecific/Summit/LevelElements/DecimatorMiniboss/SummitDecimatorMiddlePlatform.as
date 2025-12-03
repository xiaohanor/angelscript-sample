event void FSummitDecimatorMiddlePlatformSignature();

class ASummitDecimatorMiddlePlatform : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovement;
	default RotatingMovement.RotationRate = FRotator(0, 0, 0);

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitDecimatorMiddlePlatformSignature OnActivated;

	UPROPERTY()
	bool bIsPlaying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

	}

	UFUNCTION()
	void MovePlatform()
	{
		if (bIsPlaying)
			return;

		if (MoveAnimation.GetValue() == 1.0)
			return;

		// MoveAnimation.PlayFromStart();
		OnActivated.Broadcast();

	}

	UFUNCTION()
	void LiftPlatform()
	{
		// MoveAnimation.Reverse();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		MovableObject.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		MovableObject.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	UFUNCTION()
	void RotatePlatform(FRotator RotationRate)
	{
		RotatingMovement.RotationRate = RotationRate;
	}

	UFUNCTION()
	void ResetPlatform()
	{
		RotatingMovement.RotationRate = FRotator(0, 0, 0);
		LiftPlatform();
		// MovableObject.SetWorldLocation(StartingPosition);
		// MovableObject.SetWorldRotation(StartingRotation);
		// MoveAnimation.SetNewTime(0);
	}
	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
	}

}