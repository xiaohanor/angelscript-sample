UCLASS(Abstract)
class AIslandGrenadeLockIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	void SetGrenadeLockCompletionAmount(EHazePlayer Type, int Amount)
	{
		devCheck(Type != EHazePlayer::MAX);
		for(int i = 0; i < 3; i++)
		{
			if(Type == EHazePlayer::Mio)
				SetRedIndicatorActiveState(i, i < Amount);
			else
				SetBlueIndicatorActiveState(i, i < Amount);
		}
	}

	UFUNCTION(BlueprintEvent)
	void SetBlueIndicatorActiveState(int IndicatorIndex, bool bActiveState) {}

	UFUNCTION(BlueprintEvent)
	void SetRedIndicatorActiveState(int IndicatorIndex, bool bActiveState) {}

	UFUNCTION(BlueprintEvent)
	void OnGrenadeLockPuzzleComplete() {}
}