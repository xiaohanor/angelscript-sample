UCLASS(Abstract)
class ASpaceWalkSpinningPassage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(0,20,0) * DeltaSeconds);
	}
};
