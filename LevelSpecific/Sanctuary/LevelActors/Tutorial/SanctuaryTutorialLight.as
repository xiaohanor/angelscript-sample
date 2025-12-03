class ASanctuaryTutorialLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent BirdRespComp;

	UPROPERTY(EditAnywhere)
	ASpotLight Spotlight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		BirdRespComp.OnUnilluminated.AddUFunction(this, n"HandleUnIlluminated");
		Spotlight.AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		Spotlight.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandleUnIlluminated()
	{
		Spotlight.AddActorDisable(this);
	}
};