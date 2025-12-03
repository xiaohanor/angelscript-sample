UCLASS(Abstract)
class AHackableWaterTransform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AHackableWaterGear WaterGear;
};
