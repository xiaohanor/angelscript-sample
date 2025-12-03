class AForgeMoveableChute : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Chute;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Pole;

	UPROPERTY(DefaultComponent, Attach)
	USceneComponent HandleLocation1;
	
	UPROPERTY(DefaultComponent, Attach)
	USceneComponent HandleLocation2;

	UPROPERTY(DefaultComponent, Attach)
	USceneComponent WheelLoccation;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitTailDragonHandle> Handles;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitAcidDragonWheel AcidWheel;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASplineActor TrackSpline;

	float PushSpeed = 750.0;

	float RotationAmplifier = 2.5;
	float RotationSpeed;
	float CurrentDistance;

	FRotator TargetRotation;
	float RotationAmount = 30.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Handles[0].AttachToComponent(HandleLocation1, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		Handles[1].AttachToComponent(HandleLocation2, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);


		for(ASummitTailDragonHandle Handle : Handles)
		{
			Handle.OnHandleMoving.AddUFunction(this, n"OnHandleMoving");
		}
		AcidWheel.AttachToComponent(WheelLoccation, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		AcidWheel.OnSpinning.AddUFunction(this, n"OnSpinning");
		
		ActorLocation = TrackSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
		CurrentDistance = TrackSpline.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);

		TargetRotation = Chute.WorldRotation;

	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentDistance = Math::Clamp(CurrentDistance, 0.0, TrackSpline.Spline.GetSplineLength());
		ActorLocation = TrackSpline.Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
		ActorRotation = TrackSpline.Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();

		

		if(RotationSpeed == 0)
			return;

		FRotator Rotation = FRotator(0.0, RotationSpeed * DeltaSeconds, 0.0);
		Chute.AddRelativeRotation(Rotation);
		
	}

	UFUNCTION()
	private void OnSpinning(float SpinSpeed)
	{

		RotationSpeed = SpinSpeed * RotationAmplifier;
	}

	UFUNCTION()
	private void OnHandleMoving(float Forward, FVector Direction, float DeltaTime)
	{
		float Dot = ActorForwardVector.DotProduct(Direction);
		CurrentDistance += Forward * PushSpeed * Dot * DeltaTime;
			
	}

}