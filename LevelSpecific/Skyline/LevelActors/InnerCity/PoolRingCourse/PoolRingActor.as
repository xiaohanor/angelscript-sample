event void FOnPoolCourseRingOverlapped(APoolRingActor RingActor);

class APoolRingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DeformationRoot;

	UPROPERTY(DefaultComponent, Attach = DeformationRoot)
	UStaticMeshComponent RingMeshOuterBack;
	default RingMeshOuterBack.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = DeformationRoot)
	UStaticMeshComponent RingMeshOuterFront;
	default RingMeshOuterFront.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = DeformationRoot)
	UStaticMeshComponent RingMeshInnerBack;
	default RingMeshInnerBack.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = DeformationRoot)
	UStaticMeshComponent RingMeshInnerFront;
	default RingMeshInnerFront.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = DeformationRoot)
	UStaticMeshComponent RingMeshCenterEmissive;
	default RingMeshCenterEmissive.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = DeformationRoot)
	USphereComponent CollisionSphere;
	default CollisionSphere.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CollisionSphere.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ActivationFX;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UMaterialInterface Mat_Active;
	UMaterialInterface Mat_Inactive;

	bool bActive = false;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike RotationTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike ScaleTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike ReverseScaleTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike VictoryScaleTimeLike;	

	UPROPERTY()
	FOnPoolCourseRingOverlapped OnRingActivated;

	private FVector OuterInitialScale = FVector::OneVector;
	private FVector InnerInitialScale = FVector::OneVector;
	private FVector CenterInitialScale = FVector::OneVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOverlap");

		Mat_Inactive = RingMeshOuterBack.GetMaterial(0);

		RotationTimeLike.BindUpdate(this, n"OnRotationUpdate");
		ScaleTimeLike.BindUpdate(this, n"OnScaleUpdate");
		ReverseScaleTimeLike.BindUpdate(this, n"OnReverseScaleUpdate");
		VictoryScaleTimeLike.BindUpdate(this, n"OnVictoryScaleUpdate");

		OuterInitialScale = RingMeshOuterBack.RelativeScale3D;
		InnerInitialScale = RingMeshInnerBack.RelativeScale3D;
		CenterInitialScale = RingMeshCenterEmissive.RelativeScale3D;
	}

	UFUNCTION()
	private void OnScaleUpdate(float CurrentValue)
	{
		DeformationRoot.SetRelativeScale3D(FVector(CurrentValue, CurrentValue, CurrentValue));
	}

	UFUNCTION()
	private void OnReverseScaleUpdate(float CurrentValue)
	{
		DeformationRoot.SetRelativeScale3D(FVector(CurrentValue, CurrentValue, CurrentValue));
	}

	UFUNCTION()
	private void OnVictoryScaleUpdate(float CurrentValue)
	{
		DeformationRoot.SetRelativeScale3D(FVector(0.25 * CurrentValue, 0.25 * CurrentValue, 0.25 * CurrentValue));
	}

	UFUNCTION()
	private void OnRotationUpdate(float CurrentValue)
	{
		float NewYawRotation = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(0, 720), CurrentValue);

		DeformationRoot.SetRelativeRotation(FRotator(DeformationRoot.RelativeRotation.Pitch, NewYawRotation, DeformationRoot.RelativeRotation.Roll));
	}

	void PlayVictoryAnimation()
	{
		VictoryScaleTimeLike.PlayFromStart();
	}

	void ToggleRingState(bool Active)
	{
		if(Active)
		{
			RingMeshInnerBack.SetMaterial(0, Mat_Active);
			RingMeshInnerFront.SetMaterial(0, Mat_Active);
			RingMeshOuterBack.SetMaterial(0, Mat_Active);
			RingMeshOuterFront.SetMaterial(0, Mat_Active);

			// ActivationFX.Activate(true);

			bActive = true;

			ScaleTimeLike.PlayFromStart();
			RotationTimeLike.PlayFromStart();
		}
		else
		{
			RingMeshInnerBack.SetMaterial(0, Mat_Inactive);
			RingMeshInnerFront.SetMaterial(0, Mat_Inactive);
			RingMeshOuterBack.SetMaterial(0, Mat_Inactive);
			RingMeshOuterFront.SetMaterial(0, Mat_Inactive);

			bActive = false;

			ReverseScaleTimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	private void OnPlayerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
			OnRingActivated.Broadcast(this);

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.PlayForceFeedback(ForceFeedback, false, false, this, 1.0);
		}

	}
};