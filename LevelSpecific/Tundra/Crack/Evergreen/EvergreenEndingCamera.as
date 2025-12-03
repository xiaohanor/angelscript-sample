class AEvergreenEndingCamera : AStaticCameraActor
{
	UPROPERTY(EditAnywhere)
	AActor WorldPivotPoint;

	float TargetPitch = -80;
	float TargetDistance = 150.0;
	float TargetHeight = 700.0;
	float AccelerationTime = 1.5;

	FHazeAcceleratedRotator AccelRot;
	FHazeAcceleratedVector AccelVec;
	FRotator CurrentRot;
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FRotator TargetRot = FRotator(TargetPitch, CurrentRot.Yaw, CurrentRot.Roll);
		AccelRot.AccelerateTo(TargetRot, AccelerationTime, DeltaSeconds);
		AccelVec.AccelerateTo(TargetLoc, AccelerationTime, DeltaSeconds);
		ActorRotation = AccelRot.Value;
		ActorLocation = AccelVec.Value;
	}

	UFUNCTION()
	void RunCameraLogic(AHazePlayerCharacter Player)
	{
		ActorLocation = Player.GetViewLocation();
		ActorRotation = Player.GetViewRotation();
		AccelRot.SnapTo(ActorRotation);
		AccelVec.SnapTo(ActorLocation);
		CurrentRot = ActorRotation;
		FVector DirectionToPivot = (ActorLocation - WorldPivotPoint.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		TargetLoc = WorldPivotPoint.ActorLocation + (DirectionToPivot * TargetDistance);
		TargetLoc += FVector::UpVector * TargetHeight;
		Player.ActivateCamera(this, 1.5, this);
		SetActorTickEnabled(true);		
	}
};