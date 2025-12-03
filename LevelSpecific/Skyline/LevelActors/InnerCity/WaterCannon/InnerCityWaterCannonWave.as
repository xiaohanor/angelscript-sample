class AInnerCityWaterCannonWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDynamicWaterEffectDecalComponent WaterEffect;
};