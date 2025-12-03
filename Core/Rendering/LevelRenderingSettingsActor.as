/**
 * Overrides certain rendering settings for the level the actor is placed in.
 */
class ALevelRenderingSettingsActor : AHazeActor
{
	UPROPERTY(EditAnywhere, Category = "Rendering Settings", Meta = (InlineEditConditionToggle))
	bool bOverrideSubsurfaceScattering = false;
	UPROPERTY(EditAnywhere, Category = "Rendering Settings", Meta = (EditCondition = "bOverrideSubsurfaceScattering"))
	ERenderingSettingMode SubsurfaceScattering = ERenderingSettingMode::On;

	UPROPERTY(EditAnywhere, Category = "Rendering Settings", Meta = (InlineEditConditionToggle))
	bool bOverrideDynamicResolutionThrottleNormalSpec = false;
	UPROPERTY(EditAnywhere, Category = "Rendering Settings", Meta = (EditCondition = "bOverrideDynamicResolutionThrottleNormalSpec"))
	float ThrottleDynamicResolutionNormalSpec = 1.0;

	UPROPERTY(EditAnywhere, Category = "Rendering Settings", Meta = (InlineEditConditionToggle))
	bool bOverrideDynamicResolutionThrottleHighSpec = false;
	UPROPERTY(EditAnywhere, Category = "Rendering Settings", Meta = (EditCondition = "bOverrideDynamicResolutionThrottleHighSpec"))
	float ThrottleDynamicResolutionHighSpec = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		URenderingSettingsSingleton Singleton = Game::GetSingleton(URenderingSettingsSingleton);

		if (bOverrideSubsurfaceScattering)
			Singleton.EnableSubsurfaceScattering.Apply(SubsurfaceScattering, this);
		if (bOverrideDynamicResolutionThrottleNormalSpec)
			Singleton.ThrottledDynamicResNormalSpec.Apply(ThrottleDynamicResolutionNormalSpec, this);
		if (bOverrideDynamicResolutionThrottleHighSpec)
			Singleton.ThrottledDynamicResHighSpec.Apply(ThrottleDynamicResolutionHighSpec, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		URenderingSettingsSingleton Singleton = Game::GetSingleton(URenderingSettingsSingleton);
		Singleton.EnableSubsurfaceScattering.Clear(this);
		Singleton.ThrottledDynamicResNormalSpec.Clear(this);
		Singleton.ThrottledDynamicResHighSpec.Clear(this);
	}
};