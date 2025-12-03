event void FIslandHovercraftGrenadeLockSignature();

class AIslandHovercraftGrenadeLock : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;
	
	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent ConnectorMesh;

	UPROPERTY(EditAnywhere)
	AIslandPressurePlate PressurePlateRef;

	UPROPERTY(EditAnywhere)
	AIslandGrenadeLockListener GrenadeListener;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 0.22;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FIslandHovercraftGrenadeLockSignature OnInteractionStarted;

	UPROPERTY()
	FIslandHovercraftGrenadeLockSignature OnInteractionEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetRelativeTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetRelativeTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (PressurePlateRef != nullptr)
		{
			PressurePlateRef.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
			PressurePlateRef.OnInteractionEnd.AddUFunction(this, n"HandleInteractionEnd");
		}

		if (GrenadeListener != nullptr)
		{
			GrenadeListener.OnCompleted.AddUFunction(this, n"HandleOnCompleted");
		}

	}

	UFUNCTION()
	void HandleInteractionStarted()
	{
		Start();
	}
	
	UFUNCTION()
	void HandleInteractionEnd()
	{
		Reverse();
	}
		
	UFUNCTION()
	void HandleOnCompleted()
	{
		ConnectorMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.Play();
	}

	UFUNCTION()
	void Reverse()
	{
		MoveAnimation.Reverse();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		// MovableComp.SetRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		// MovableComp.SetRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		SetActorRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	
	UFUNCTION()
	void OnFinished()
	{


	}



}