class AConveyerSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UConveyerSplineMovementCapability);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6500.0;

	UPROPERTY()
	TSubclassOf<ASolarFlareMiningConveyerObject> PlatformClass;
	UPROPERTY()
	TSubclassOf<ASolarFlareMiningConveyerObject> ContainerClass;

	UPROPERTY(EditAnywhere)
	float Separation = 150.0;

	UPROPERTY(EditAnywhere)
	float ConveyerSpeed = 250.0;

	TArray<ASolarFlareMiningConveyerObject> Objects;

	int ContainerPlatformDistance = 6;

	float SpawnRate = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		int SpawnDistance = Math::FloorToInt(Spline.SplineLength / Separation);

		float CurrentDistance = 0;
		float ContainerCounter = 0;

		for (int i = 0; i < SpawnDistance; i++)
		{
			FVector Location = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
			FRotator Rotation = Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();
			ASolarFlareMiningConveyerObject Platform =  SpawnActor(PlatformClass, Location, Rotation, bDeferredSpawn = true);
			Platform.SplineComp = Spline;
			Platform.StartingSplineDist = CurrentDistance;
			FinishSpawningActor(Platform);
			Objects.Add(Platform);

			CurrentDistance += Separation;
			ContainerCounter++;

			if (ContainerCounter == ContainerPlatformDistance)
			{
				ContainerCounter = 0;
				ASolarFlareMiningConveyerObject Container =  SpawnActor(ContainerClass, Location, Rotation, bDeferredSpawn = true);
				Container.MakeNetworked(this, i);
				Container.SplineComp = Spline;
				Container.StartingSplineDist = CurrentDistance;
				FinishSpawningActor(Container);
				Objects.Add(Container);
			}
		}
	}
};

class UConveyerSplineMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	AConveyerSpline ConveyorSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ConveyorSpline = Cast<AConveyerSpline>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (ASolarFlareMiningConveyerObject Object : ConveyorSpline.Objects)
		{
			float Move = Math::Wrap(Object.StartingSplineDist + (ConveyorSpline.ConveyerSpeed * Time::PredictedGlobalCrumbTrailTime), 0, ConveyorSpline.Spline.SplineLength);
			Object.SplinePos = ConveyorSpline.Spline.GetSplinePositionAtSplineDistance(Move);
			Object.UpdateMove();
		}
	}
}