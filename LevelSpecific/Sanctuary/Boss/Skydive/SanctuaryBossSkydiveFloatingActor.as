class ASanctuaryBossSkydiveFloatingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USanctuarySkydiveFloatingComponent FloatingComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryBossHydraResponseComponent HydraResponseComp;

	UPROPERTY(EditAnywhere)
	float Distance = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FloatingComponent.PreviewDistance = Distance;
		FloatingComponent.Update(Distance);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};