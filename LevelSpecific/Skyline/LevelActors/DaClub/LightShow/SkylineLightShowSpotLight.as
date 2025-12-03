class ASkylineLightShowSpotLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USpotLightComponent SpotLight;

	UPROPERTY(DefaultComponent)
	UGodrayComponent Godray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};