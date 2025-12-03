UCLASS(Abstract)
class AVillageCanalWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WheelRoot;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		WheelRoot.AddLocalRotation(FRotator(0.0, 0.0, 40.0 * DeltaTime));
	}
}