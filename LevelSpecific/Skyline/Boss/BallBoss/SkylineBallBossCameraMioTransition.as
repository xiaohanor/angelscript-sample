class ASkylineBallBossCameraMioTransition : AStaticCameraActor
{
	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		AccelRot.SnapTo(ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector TargetLoc = Game::Mio.ActorLocation;
		TargetLoc += FVector::UpVector * 100.0;
		FRotator TargetRot = (TargetLoc - ActorLocation).Rotation();
		AccelRot.AccelerateTo(TargetRot, 1.0, DeltaSeconds);
		ActorRotation = AccelRot.Value;
	}

	UFUNCTION()
	void SetCameraActive(bool bIsActive)
	{
		SetActorTickEnabled(bIsActive);
	}
};