class ASanctuarySplineRunLightDiscManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor KineticActor;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KineticActor.PlatformMesh.AddComponentCollisionBlocker(this);

		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnIlluminated");
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		KineticActor.PlatformMesh.RemoveComponentCollisionBlocker(this);
	}

	UFUNCTION()
	private void HandleUnIlluminated()
	{
		KineticActor.PlatformMesh.AddComponentCollisionBlocker(this);
	}
};