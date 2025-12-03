class AMeltdownWorldSpinActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	FRotator StartRotation;

	UPROPERTY(EditAnywhere)
	bool bAccelerateToRotation = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bAccelerateToRotation"))
	float Acceleration = 2.0;

	FHazeAcceleratedRotator AccRotation;
	AMeltdownWorldSpinManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = GetActorRotation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();
		if (Manager == nullptr)
			return;

		FRotator TargetRotation = StartRotation.Compose(Manager.WorldSpinRotation.Rotator());

		if(bAccelerateToRotation)
		{
			AccRotation.AccelerateTo(TargetRotation, 1.0 / Acceleration, DeltaSeconds);
			SetActorRotation(AccRotation.Value);
		}
		else
		{
			SetActorRotation(TargetRotation);
		}
	}
}