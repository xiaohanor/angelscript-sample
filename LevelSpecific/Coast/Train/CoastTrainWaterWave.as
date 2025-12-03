class ACoastTrainWaterWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.WorldScale3D = FVector(2);

	UPROPERTY(EditAnywhere)
	APropLine WaterSurface;

	TArray<UHazePropSplineMeshComponent> SplinePropComponents;

	UMaterialInstanceDynamic Material0;
	UMaterialInstanceDynamic Material1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(WaterSurface == nullptr)
			return;
		
		WaterSurface.GetComponentsByClass(SplinePropComponents);
		
		Material0 = SplinePropComponents[0].CreateDynamicMaterialInstance(0);
		Material1 = SplinePropComponents[0].CreateDynamicMaterialInstance(1);

		for (int i = 0; i < SplinePropComponents.Num(); i++)
		{
			SplinePropComponents[i].SetMaterial(0, Material0);
		}

		for (int i = 0; i < SplinePropComponents.Num(); i++)
		{
			SplinePropComponents[i].SetMaterial(1, Material1);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(WaterSurface == nullptr)
			return;

		Material0.SetVectorParameterValue(n"TrainLocation", FLinearColor(GetActorLocation()));
		Material1.SetVectorParameterValue(n"TrainLocation", FLinearColor(GetActorLocation()));

		Material0.SetVectorParameterValue(n"TrainDirection", FLinearColor(GetActorForwardVector()));
		Material1.SetVectorParameterValue(n"TrainDirection", FLinearColor(GetActorForwardVector()));
	}
};