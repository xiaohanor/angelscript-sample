

class AArenaCrowd : AHazeActor
{
	// test
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintPure)
	AArenaBoss GetBoss() const
	{
		return Arena::GetBoss();
	}
}