class ASanctuaryBossInsideRoot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingSceneComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FloatingSceneComponent.SetComponentTickEnabled(false);
	}

	UFUNCTION()
	void Activate()
	{
		FloatingSceneComponent.SetComponentTickEnabled(true);
	}
};