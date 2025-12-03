class USkylineClubDancingUserComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UAnimSequence MioDance;

	UPROPERTY(EditAnywhere)
	UAnimSequence ZoeDance;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere)
	FLinearColor SpotLightA_Color = FLinearColor::White;

	UPROPERTY(EditAnywhere)
	float SpotLightA_Intensity = 20.0;

	UPROPERTY(EditAnywhere)
	UMaterialInterface LightFunctionMaterialA;

	UPROPERTY(EditAnywhere)
	FLinearColor SpotLightB_Color = FLinearColor::White;

	UPROPERTY(EditAnywhere)
	float SpotLightB_Intensity = 100.0;

	UPROPERTY(EditAnywhere)
	UMaterialInterface LightFunctionMaterialB;

	UPROPERTY(EditAnywhere)
	float CameraRotationSpeed = 30.0;

	bool bIsDancing = false;
	bool bIsCameraSpinning = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};