class ASolarFlareEnergyMechanism : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent EnergyRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	float TargetEnergy;
	float CurrentEnergy = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshComp.SetScalarParameterValueOnMaterialIndex(1, n"Blend", 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentEnergy = Math::FInterpConstantTo(CurrentEnergy, TargetEnergy, DeltaSeconds, 1.0);
		CurrentEnergy = Math::Clamp(CurrentEnergy, 0.0001, 1.0);

		MeshComp.SetScalarParameterValueOnMaterialIndex(1, n"Blend", CurrentEnergy / 5);
	}

	void UpdateTargetEnergy(float NewTarget)
	{
		TargetEnergy = NewTarget;
	}
};