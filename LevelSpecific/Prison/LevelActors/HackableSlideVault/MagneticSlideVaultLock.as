class AMagneticSlideVaultLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagnetSurfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};