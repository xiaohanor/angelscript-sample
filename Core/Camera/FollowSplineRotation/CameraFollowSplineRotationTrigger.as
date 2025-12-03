class ACameraFollowSplineRotationTrigger : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;

	UPROPERTY(EditAnywhere)
	FCameraFollowSplineRotationSettings Settings;

	UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Low;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEntered");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeft");
	}

	UFUNCTION()
	protected void OnPlayerEntered(AHazePlayerCharacter Player)
	{
		Player.ApplyCameraFollowSplineRotation(Spline.Spline, this, Settings, Priority = Priority);
	}

	UFUNCTION()
	protected void OnPlayerLeft(AHazePlayerCharacter Player)
	{
		Player.ClearCameraFollowSplineRotation(this);
	}
};