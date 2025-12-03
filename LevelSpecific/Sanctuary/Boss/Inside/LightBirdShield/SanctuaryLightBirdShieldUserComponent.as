class USanctuaryLightBirdShieldUserComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	USanctuaryLightBirdShieldSettings Settings;

//	UPROPERTY(EditDefaultsOnly)
//	TSubclassOf<ASanctuaryLightBirdShield> LightBirdShieldClass;
	ASanctuaryLightBirdShield LightBirdShield;

//	UPROPERTY(EditDefaultsOnly)
//	TSubclassOf<AActor> EffectActorClass;
	AActor EffectActor;

//	UPROPERTY(EditDefaultsOnly)
//	UNiagaraSystem DarknessVFX;
	UNiagaraComponent DarknessComp;

//	UPROPERTY(EditDefaultsOnly)
//	UAnimSequence DarknessDownAnim;

//	UPROPERTY(EditDefaultsOnly)
//	UAnimSequence DarknessCrawlAnim;

//	UPROPERTY(EditDefaultsOnly)
//	TArray<UHazeComposableSettings> DarknessCrawlSettings;

//	UPROPERTY(EditDefaultsOnly)
//	UForceFeedbackEffect DarknessForceFeedbackEffect;

//	UPROPERTY(EditDefaultsOnly)
//	TArray<UHazeComposableSettings> Settings;

//	UPROPERTY(EditDefaultsOnly)
//	TArray<UHazeComposableSettings> DarknessSettings;

/*
	UPROPERTY(EditDefaultsOnly)
	TArray<FName> BlockTagsInDarkness;
	default BlockTagsInDarkness.Add(PlayerMovementTags::Jump);
	default BlockTagsInDarkness.Add(PlayerMovementTags::Dash);
	default BlockTagsInDarkness.Add(PlayerMovementTags::Sprint);
	default BlockTagsInDarkness.Add(PlayerMovementTags::WallScramble);
	default BlockTagsInDarkness.Add(PlayerMovementTags::LedgeMantle);
	default BlockTagsInDarkness.Add(PlayerMovementTags::LedgeGrab);
	default BlockTagsInDarkness.Add(PlayerMovementTags::WallRun);
*/

	TInstigated<float> DarknessRate;
	default DarknessRate.DefaultValue = 0.0;
	float DarknessAmount = 0.0;

	TArray<AActor> DarknessVolumes;
	int InsideDarknessVolumes = 0;

	bool bIsActive = false;
	TInstigated<bool> bIsCrawling;
	default bIsCrawling.DefaultValue = false;

	TInstigated<bool> bUseFocusCamera;
	default bUseFocusCamera.DefaultValue = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};