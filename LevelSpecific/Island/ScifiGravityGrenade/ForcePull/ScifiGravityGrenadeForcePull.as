class AScifiGravityGrenadeForcePull : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UScifiGravityGrenadeTargetableComponent TargetComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent TargetScene;
	FTransform StartTransform;
	FTransform EndTransform;
	FTransform TargetTransform;

	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedQuat;

	TArray<AScifiGravityGrenadeForcePull> ConnectedObjects;

	UPROPERTY(EditAnywhere)
	float ForwardStiffness = 10;
	UPROPERTY(EditAnywhere)
	float ForwardDampening = 0.8;
	UPROPERTY(EditAnywhere)
	float BackwardsStiffness = 5;
	UPROPERTY(EditAnywhere)
	float BackwardsDampening = 0.8;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	void SetDelayedActivation(bool bShouldActivate, float Delay)
	{
		
	}

	void ForcePullStart()
	{
		Print("ForcePullStart", 5);
		ActorTickEnabled = true;
		TargetTransform = EndTransform;
	}

	void ForcePullStopped()
	{
		Print("ForcePullStopped", 5);
		ActorTickEnabled = true;
		TargetTransform = StartTransform;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTransform = GetActorTransform();
		AcceleratedLocation.Value = StartTransform.GetLocation();
		AcceleratedQuat.Value = StartTransform.GetRotation();
		EndTransform = TargetScene.GetWorldTransform();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedLocation.SpringTo(TargetTransform.Location, 1 * ForwardStiffness , 1 * ForwardDampening, DeltaSeconds);
		AcceleratedQuat.SpringTo(TargetTransform.Rotation, 1 * ForwardStiffness , 1 * ForwardDampening, DeltaSeconds);
		
		Print("Ticking", 0);

		if(AcceleratedQuat.Value.Rotator().Equals(TargetTransform.Rotation.Rotator(), 0.1) 
		&& AcceleratedLocation.Value.Equals(TargetTransform.Location, 0.1))
		{
			AcceleratedLocation.Value = TargetTransform.Location;
			AcceleratedQuat.Value = TargetTransform.Rotation;

			ActorTickEnabled = false;
		}

		SetActorLocationAndRotation(AcceleratedLocation.Value, AcceleratedQuat.Value.Rotator());
	}
}