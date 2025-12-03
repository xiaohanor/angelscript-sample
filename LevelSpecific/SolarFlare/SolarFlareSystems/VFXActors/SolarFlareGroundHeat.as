class ASolarFlareGroundHeat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent DecalComp;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor EventImpactActor;

	UPROPERTY(EditAnywhere)
	float Speed = 1.0;

	UPROPERTY(EditAnywhere)
	float TileX = 4.0;

	UPROPERTY(EditAnywhere)
	float TileY = 4.0;

	UPROPERTY()
	UMaterialInstanceDynamic DynamicMat;	

	float TargetEmiss = 1.0;
	float CurrentEmiss;
	float EmissSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DynamicMat = DecalComp.CreateDynamicMaterialInstance();
		DynamicMat.SetScalarParameterValue(n"TileX", TileX);
		DynamicMat.SetScalarParameterValue(n"TileY", TileY);	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynamicMat = DecalComp.CreateDynamicMaterialInstance();
		DynamicMat.SetScalarParameterValue(n"TileX", TileX);
		DynamicMat.SetScalarParameterValue(n"TileY", TileY);
		EventImpactActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DynamicMat.SetScalarParameterValue(n"TileX", TileX);
		DynamicMat.SetScalarParameterValue(n"TileY", TileY);
		DynamicMat.SetScalarParameterValue(n"Speed_X", Time::GameTimeSeconds * Speed);

		if (CurrentEmiss > 0.0)
		{
			CurrentEmiss -= EmissSpeed * DeltaSeconds;
			CurrentEmiss = Math::Clamp(CurrentEmiss, 0, 1.0);
		}

		DynamicMat.SetScalarParameterValue(n"Emiss_Intensity", CurrentEmiss);
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		CurrentEmiss = TargetEmiss;
	}
};