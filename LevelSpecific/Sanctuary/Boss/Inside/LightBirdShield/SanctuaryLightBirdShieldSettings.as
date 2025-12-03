class USanctuaryLightBirdShieldSettings : UHazeComposableSettings
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryLightBirdShield> LightBirdShieldClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AActor> EffectActorClass;

	UPROPERTY(EditDefaultsOnly)
	UMaterialParameterCollection GlobalParametersVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DarknessVFX;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor FaceLightColor = FLinearColor::Red;

	UPROPERTY(EditDefaultsOnly)
	float FaceLightIntensity = 1000.0;

	UPROPERTY(EditDefaultsOnly)
	int DarknessVFXSorting = 300;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeComposableSettings> DarknessCrawlSettings;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DarknessForceFeedbackEffect;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeComposableSettings> Settings;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeComposableSettings> MioSettings;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeComposableSettings> ZoeSettings;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeCameraSpringArmSettingsDataAsset> MioCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeCameraSpringArmSettingsDataAsset> ZoeCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeComposableSettings> DarknessSettings;


	UPROPERTY(EditDefaultsOnly)
	TArray<FName> BlockTags;
	default BlockTags.Add(PlayerMovementTags::AirJump);
	default BlockTags.Add(PlayerMovementTags::AirDash);
	default BlockTags.Add(PlayerMovementTags::Dash);
	default BlockTags.Add(PlayerMovementTags::Sprint);
	default BlockTags.Add(PlayerMovementTags::WallScramble);
	default BlockTags.Add(PlayerMovementTags::LedgeMantle);
	default BlockTags.Add(PlayerMovementTags::LedgeGrab);
	default BlockTags.Add(PlayerMovementTags::WallRun);

	UPROPERTY(EditDefaultsOnly)
	TArray<FName> BlockTagsInDarkness;
	default BlockTagsInDarkness.Add(PlayerMovementTags::Jump);
	default BlockTagsInDarkness.Add(PlayerMovementTags::Dash);
	default BlockTagsInDarkness.Add(PlayerMovementTags::Sprint);
	default BlockTagsInDarkness.Add(PlayerMovementTags::WallScramble);
	default BlockTagsInDarkness.Add(PlayerMovementTags::LedgeMantle);
	default BlockTagsInDarkness.Add(PlayerMovementTags::LedgeGrab);
	default BlockTagsInDarkness.Add(PlayerMovementTags::WallRun);
	default BlockTagsInDarkness.Add(PlayerMovementTags::Perch);

	UPROPERTY(EditDefaultsOnly)
	float DarknessRate = 0.25;

	UPROPERTY(EditDefaultsOnly)
	EHazeSelectPlayer CrawlingPlayer;
}