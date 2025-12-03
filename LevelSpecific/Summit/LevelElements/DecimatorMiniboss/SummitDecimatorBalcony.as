event void FSummitDecimatorBalconySignature();

class ASummitDecimatorBalcony : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComp;

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
	FSummitDecimatorBalconySignature OnPlatformDestroyed;

	UPROPERTY()
	int HP = 6;

	int CurrentHP = HP;

	UPROPERTY()
	bool bIsPlaying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// StartingTransform = MeshRootComp.GetWorldTransform();
		// StartingPosition = StartingTransform.GetLocation();
		// StartingRotation = StartingTransform.GetRotation();

		// EndingTransform = EndingPositionComp.GetWorldTransform();
		// EndingPosition = EndingTransform.GetLocation();
		// EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		
	}

	UFUNCTION()
	void DealDamage(int Damage)
	{
		CurrentHP = CurrentHP - Damage;

		if (CurrentHP <= 0)
		{
			//destroy platform
			OnPlatformDestroyed.Broadcast();
			BP_DestroyPlatform();
			return;
		}

		BP_DestroyPillar(Damage);

		// MoveAnimation.Play();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		// MeshRootComp.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		// MeshRootComp.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}
	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyPillar(int Damage)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyPlatform()
	{
		
	}

}