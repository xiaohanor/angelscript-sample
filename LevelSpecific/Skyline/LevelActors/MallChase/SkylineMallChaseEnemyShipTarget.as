class USkylineMallChaseEnemyShipTargetComponent : USceneComponent
{

}

class ASkylineMallChaseEnemyShipTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};