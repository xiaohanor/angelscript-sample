class ADragonHelp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent Spline;

	FSplinePosition SplinePos;

	bool bDragonHelp;

	bool bDragonFlyOff;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 3000.0;
	float StartMoveSpeed = 3000.0;

	UPROPERTY(EditAnywhere)
	bool bResetAtSplineEnd = false;

	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
		if (SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			SplinePos = Spline.GetSplinePositionAtSplineDistance(0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDragonHelp)
		{
			SplinePos.Move(MoveSpeed * DeltaSeconds);
			ActorLocation = SplinePos.WorldLocation;
			ActorRotation = SplinePos.WorldRotation.Rotator();
			Debug::DrawDebugSphere(SplinePos.WorldLocation, 300.0, 12, FLinearColor::Red);

			if (bResetAtSplineEnd)
			{
				if (SplinePos.CurrentSplineDistance >= SplinePos.CurrentSpline.SplineLength - 1.0)
				{
					ActorLocation = StartLoc;
					bDragonHelp = false;
				}
			}
		}

		if (bDragonFlyOff)
		{
			FVector Loc = ActorLocation + ActorForwardVector * 100.0;
			Loc += FVector::UpVector * 50.0;
			FVector Direction = (Loc - ActorLocation).GetSafeNormal();
			ActorLocation += Direction * MoveSpeed * DeltaSeconds;
		}
	}

	UFUNCTION()
	void ActivateDragonHelp(ASplineActor HelpSpline = nullptr, float NewMoveSpeed = 0.0)
	{
		bDragonHelp = true;

		if (NewMoveSpeed > 0.0)
			MoveSpeed = NewMoveSpeed;

		if (HelpSpline != nullptr)
		{
			Spline = HelpSpline.Spline;
			SplinePos = Spline.GetSplinePositionAtSplineDistance(0);
		}
	}

	UFUNCTION()
	void DeactivateDragonHelp()
	{
		bDragonHelp = false;
		bDragonFlyOff = true;
	}
};