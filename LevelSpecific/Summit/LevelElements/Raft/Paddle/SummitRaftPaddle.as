UCLASS(Abstract)
class ASummitRaftPaddle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PaddleTop;

	UPROPERTY(DefaultComponent)
	USceneComponent PaddleBottom;

	UPROPERTY(DefaultComponent)
	URaftWaterSampleComponent WaterSampleComp;
};
