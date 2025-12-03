UCLASS(Abstract)
class ULoadingTransistionScreen : UHazeUserWidget
{
	TArray<FString> ActiveLevels;
	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		SetWidgetPersistent(true);
		SetWidgetZOrderInLayer(0);
		ActiveLevels = Progress::GetActiveLevels();

		UFadeSingleton FadeSingleton = UFadeSingleton::Get();
		FadeSingleton.ActiveLoadingTransitions.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		UFadeSingleton FadeSingleton = UFadeSingleton::Get();
		FadeSingleton.ActiveLoadingTransitions.Remove(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_TransistionOver()
	{

	}

	bool bTransistioned = false;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(ActiveLevels != Progress::GetActiveLevels() && !Game::IsInLoadingScreen() && !bTransistioned)
		{
			bTransistioned = true;
			BP_TransistionOver();
		}
	}
};