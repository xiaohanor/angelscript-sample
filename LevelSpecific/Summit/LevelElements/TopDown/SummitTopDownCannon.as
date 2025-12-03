event void FSummitTopDownCannonSignature();

class ASummitTopDownCannon : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComp;

	UPROPERTY(DefaultComponent, Attach =  MeshRootComp)
	UStaticMeshComponent TailResponseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	USceneComponent MovingRootComp;

	UPROPERTY(DefaultComponent, Attach = MovingRootComp)
	USceneComponent LeftWingComp;
	
	UPROPERTY(DefaultComponent, Attach = MovingRootComp)
	USceneComponent RightWingComp;

    UPROPERTY(DefaultComponent)
	USceneComponent ActivatedLocation;
    FVector StartLocation;
    FVector EndLocation;
	FRotator StartRotationLeft;
	FRotator EndRotationLeft;
	FRotator StartRotationRight;
	FRotator EndRotationRight;
	
	UPROPERTY(DefaultComponent, Attach = TailResponseMesh)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovement;
	default RotatingMovement.RotationRate = FRotator(0, 0, 0);

	UPROPERTY(EditAnywhere)
	bool bOneTimeUse = true;

	UPROPERTY(EditInstanceOnly)
	ANightQueenMetal MeltComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AGiantBreakableObject> BreakableObjects;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

    UPROPERTY(BlueprintReadOnly)
	bool bFinishedAnimation;

	UPROPERTY(BlueprintReadOnly)
	bool bActivated;

	UPROPERTY(BlueprintReadOnly)
	bool bCompleted;

	bool bCanBeKnocked;
	
	UPROPERTY()
	FSummitTopDownCannonSignature OnActivated;

	UPROPERTY(EditInstanceOnly)
	AAISummitDecimatorTopdown DecimatorRef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        StartLocation = MovingRootComp.GetRelativeLocation();
        EndLocation = ActivatedLocation.GetRelativeLocation();

		StartRotationLeft = LeftWingComp.GetRelativeRotation();
		EndRotationLeft = FRotator(0,-45,0);

		StartRotationRight = RightWingComp.GetRelativeRotation();
		EndRotationRight = FRotator(0,45,0);

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		// SetActorTickEnabled(false);
		MeltComp.OnNightQueenMetalMelted.AddUFunction(this, n"OnMelted");
		MeltComp.OnNightQueenMetalRecovered.AddUFunction(this, n"OnRestored");
	}

	UFUNCTION()
	private void OnRestored()
	{
		bCanBeKnocked = false;
	}

	UFUNCTION()
	private void OnMelted()
	{
		bCanBeKnocked = true;
	}


	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		// MovingRootComp.SetRelativeLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
		LeftWingComp.SetRelativeRotation(Math::LerpShortestPath(StartRotationLeft, EndRotationLeft, Alpha));
		RightWingComp.SetRelativeRotation(Math::LerpShortestPath(StartRotationRight, EndRotationRight, Alpha));
	}

	UFUNCTION()
	void StartAnimation()
	{
        MoveAnimation.Play();
		OnActivated.Broadcast();
		BP_OnActivated();

		// if (BreakableObjects)
		// {
			for (auto BreakableObject : BreakableObjects)
			{			
				BreakableObject.OnBreakGiantObject(FVector(0), 3500000);
			}
		// }
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bCanBeKnocked)
			return;

		if(bCompleted)
			return;

		bActivated = true;
		StartAnimation();
	}
	
	UFUNCTION()
	void OnFinished()
	{
		bFinishedAnimation = !MoveAnimation.IsReversed();

		if (bFinishedAnimation)
		{
			MoveAnimation.Reverse();
			bActivated = false;
			BP_OnDeactivated();
			if (bOneTimeUse)
				bCompleted = true;
		}
		
	}

	UFUNCTION()
	void DeactivateStatue()
	{
		bCompleted = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinished()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated()
	{
		
	}

	UFUNCTION()
	void ActivateMoveUp()
	{
		BP_ActivateMoveUp();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateMoveUp()
	{
		
	}

}