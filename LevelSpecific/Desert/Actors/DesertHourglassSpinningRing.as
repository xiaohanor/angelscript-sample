UCLASS(Abstract)
class ADesertHourglassSpinningRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RingRoot;

	float RotationSpeed = 10.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RingRoot.AddWorldRotation(FRotator(0.0, RotationSpeed * DeltaTime, 0.0));
	}
}