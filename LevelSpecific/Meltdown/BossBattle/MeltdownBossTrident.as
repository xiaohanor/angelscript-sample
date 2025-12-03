event void FOnSecondComplete();
event void FOnComplete();

UCLASS(Abstract)
class AMeltdownBossTrident : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FOnComplete TridentComplete;

	UPROPERTY()
	FOnSecondComplete SecondTridentComplete;

	UFUNCTION(BlueprintCallable)
	void TridentDone()
	{
		TridentComplete.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void SecondTridentDone()
	{
		SecondTridentComplete.Broadcast();
	}
};
