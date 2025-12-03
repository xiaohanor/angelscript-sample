event void FPinballBossRocketOnReachForward();

UCLASS(Abstract)
class APinballBossRocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent VisualRoot;

	UPROPERTY()
	bool bLaunch;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bLaunch)
			VisualRoot.AddRelativeRotation(FQuat(FVector::UpVector, Math::DegreesToRadians(400 * DeltaSeconds)));
	}
};
