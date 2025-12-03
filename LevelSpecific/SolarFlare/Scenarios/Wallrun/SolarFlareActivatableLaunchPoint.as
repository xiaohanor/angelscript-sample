class ASolarFlareActivatableLaunchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LaunchRoot;

	UPROPERTY(DefaultComponent)
	USolarFlareWallrunInteractionResponseComponent ResponseComp;

	FVector TargetLoc;
	FVector StartLoc;
	float MoveSpeed = 1500.0;

	UPROPERTY(EditAnywhere)
	AGrappleLaunchPoint LaunchPoint;

	UPROPERTY(EditAnywhere)
	int RequiredInteractCount = 2;
	int InteractCount;

	float ValidTime;
	float ValidDuration = 4.0;

	float OpenTime;
	float OpenDuration = 7.0;

	bool bWasActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = LaunchRoot.RelativeLocation;
		TargetLoc = StartLoc + FVector(0.0, 0.0, 700.0);

		LaunchPoint.AddActorDisable(this);
		ResponseComp.OnSolarFlareWallrunInteractionActivated.AddUFunction(this, n"OnSolarFlareWallrunInteractionActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector CurentTargetLoc = StartLoc;

		if (bWasActivated)
			CurentTargetLoc = TargetLoc; 

		LaunchRoot.RelativeLocation = Math::VInterpConstantTo(LaunchRoot.RelativeLocation, CurentTargetLoc, DeltaSeconds, MoveSpeed);

		if (bWasActivated && Time::GameTimeSeconds > OpenTime)
		{
			// BP_LaunchPointDeactivated();
			LaunchPoint.AddActorDisable(this);
			bWasActivated = false;			
		}
	}

	UFUNCTION()
	private void OnSolarFlareWallrunInteractionActivated()
	{
		if (bWasActivated)
			return;

		if (Time::GameTimeSeconds > ValidTime && InteractCount != 0)
		{
			InteractCount = 0;
			return;
		}

		InteractCount++;
		ValidTime = Time::GameTimeSeconds + ValidDuration;

		if (InteractCount >= RequiredInteractCount)
		{
			// BP_LaunchPointActivated();
			OpenTime = Time::GameTimeSeconds + OpenDuration;
			LaunchPoint.RemoveActorDisable(this);
			bWasActivated = true;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPointActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPointDeactivated() {}
}