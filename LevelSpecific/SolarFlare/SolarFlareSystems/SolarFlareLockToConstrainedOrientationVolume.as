class ASolarFlareLockToConstrainedOrientationVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		FVector ConstrainedForward = TargetActor.ActorRightVector.ConstrainToPlane(FVector::UpVector);
		FVector ConstrainedRight = TargetActor.ActorForwardVector.ConstrainToPlane(FVector::UpVector);
		Player.LockInputToPlane(this, ConstrainedForward, ConstrainedRight);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearLockInputToPlane(this);
	}
}