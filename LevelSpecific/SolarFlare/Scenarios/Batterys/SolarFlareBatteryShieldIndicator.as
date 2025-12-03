class ASolarFlareBatteryShieldIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UScenepointComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight2;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GodrayRed1;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GodrayRed2;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GodrayBlue1;
	default GodrayBlue1.SetHiddenInGame(true);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GodrayBlue2;
	default GodrayBlue2.SetHiddenInGame(true);

	UPROPERTY()
	UMaterialInterface BatteryOn;
	UMaterialInterface BatteryOff;

	float TargetRotSpeed = 180.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BatteryOff = MeshComp.GetMaterial(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.AddLocalRotation(FRotator(0.0, TargetRotSpeed * DeltaSeconds, 0.0));
	}

	void TurnOn()
	{
		MeshComp.SetMaterial(0, BatteryOn);
		GodrayBlue1.SetHiddenInGame(false);
		GodrayBlue2.SetHiddenInGame(false);
		GodrayRed1.SetHiddenInGame(true);
		GodrayRed2.SetHiddenInGame(true);
		SpotLight1.SetLightColor(FLinearColor::LucBlue);
		SpotLight2.SetLightColor(FLinearColor::LucBlue);
	}

	void TurnOff()
	{
		MeshComp.SetMaterial(0, BatteryOff);
		GodrayBlue1.SetHiddenInGame(true);
		GodrayBlue2.SetHiddenInGame(true);
		GodrayRed1.SetHiddenInGame(false);
		GodrayRed2.SetHiddenInGame(false);
		SpotLight1.SetLightColor(FLinearColor::Red);
		SpotLight2.SetLightColor(FLinearColor::Red);
	}
};