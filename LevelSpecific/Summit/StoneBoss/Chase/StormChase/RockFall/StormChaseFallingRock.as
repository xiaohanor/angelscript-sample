class AStormChaseFallingRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += -FVector::UpVector * 6000.0;
		ActorRotation += FRotator(50.0, 0.0, 0.0) * DeltaSeconds;
	}
}