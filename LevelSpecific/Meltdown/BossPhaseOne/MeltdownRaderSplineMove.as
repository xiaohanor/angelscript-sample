class AMeltdownRaderSplineMove : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseOne Rader;

	UPROPERTY(EditAnywhere)
	AStaticMeshActor CubeTarget;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Ptrigger;

	float CurrentDistance = 0.0;

	float TargetDistance;

	float Speed = 0.1;

	AHazeActor ClosestPlayer;

	AHazePlayerCharacter Player;

	FHazeAcceleratedFloat AccCurrentDistance;
	
	FHazeAcceleratedRotator AccCurrentRotation;
	
	FHazeTimeLike Moving;
	default Moving.Duration = 30;
	default Moving.UseLinearCurveZeroToOne();

	UPROPERTY()
	FVector RaderOriginalPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
		TargetDistance = Spline.SplineLength;

		Ptrigger.OnActorBeginOverlap.AddUFunction(this, n"RaderReset");

		AddActorDisable(this);
	}


	UFUNCTION()
	private void RaderReset(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Overlap = Cast<AHazePlayerCharacter>(OtherActor);

		if(Overlap != nullptr)
		{
			Rader.SetActorLocation(CubeTarget.ActorLocation);
			Rader.SetActorScale3D(FVector(1.0,1.0,1.0));
			Rader.SetActorRotation(CubeTarget.ActorRotation);
			AddActorDisable(this);

			Rader.IdleFeature = NAME_None;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetDistance(DeltaSeconds);
		LookAtLocation(DeltaSeconds);	
	}

	void LookAtLocation(float DeltaSeconds)
	{
		auto AverageLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		FVector Direction = (AverageLocation - Rader.ActorLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector);
		FRotator RotationTarget = Direction.Rotation();
		AccCurrentRotation.AccelerateTo(RotationTarget, 5.0, DeltaSeconds);
		Rader.SetActorRotation(AccCurrentRotation.Value);
		PrintToScreen("" + AccCurrentRotation.Value);
	}

	void SetDistance(float DeltaSeconds)
	{
		Player = Game::GetClosestPlayer(ActorLocation);
		CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation) + 12000;
		AccCurrentDistance.AccelerateTo(CurrentDistance, 1.0, DeltaSeconds);

		auto RaderLocation = Spline.GetWorldLocationAtSplineDistance(AccCurrentDistance.Value); 
		Rader.SetActorLocation(RaderLocation);

		FVector RaderForward = Rader.ActorForwardVector;
		FVector SplineForward = -Spline.GetWorldForwardVectorAtSplineDistance(AccCurrentDistance.Value);

		Rader.SlideLeanValue = Math::Clamp(SplineForward.GetAngleDegreesTo(RaderForward)/90.0, -1.0, 1.0);
		Rader.bSlideMoving = AccCurrentDistance.Value < Spline.SplineLength;
	}

	UFUNCTION(BlueprintCallable)
	void StartRader()
	{
		RemoveActorDisable(this);

		Rader.SetActorScale3D(FVector(0.5,0.5,0.5));

		Player = Game::GetClosestPlayer(ActorLocation);
		CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation) + 12000;
		AccCurrentDistance.SnapTo(CurrentDistance);
		auto RaderLocation = Spline.GetWorldLocationAtSplineDistance(AccCurrentDistance.Value); 
		Rader.SetActorLocation(RaderLocation);

		auto AverageLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		FVector Direction = (AverageLocation - Rader.ActorLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector);
		FRotator RotationTarget = Direction.Rotation();
		AccCurrentRotation.SnapTo(RotationTarget);
		Rader.SetActorRotation(AccCurrentRotation.Value);

		Rader.IdleFeature = n"SlideChase";
		Rader.bSlideMoving = true;
	}


};