class ASkylineBikeTowerEnemyShipMissileTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	default Arrow.ArrowLength = 100.0;
	default Arrow.ArrowSize = 10.0;
	default Arrow.RelativeLocation = FVector::ForwardVector * -1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};