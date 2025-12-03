#if EDITOR

class UPropLineEditorSubsystem : UHazeEditorSubsystem
{
	TArray<TWeakObjectPtr<APropLine>> PropLinesPendingUpdate;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Deinitialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FAngelscriptExcludeScopeFromLoopTimeout ExcludeFromTimeout;

		// Update all proplines that were set pending when we loaded the level 
		for (auto PropLine : PropLinesPendingUpdate)
		{
			if (PropLine.IsValid())
			{
				FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(PropLine.Get());
				PropLine.Get().UpdatePropLine();
			}
		}

		PropLinesPendingUpdate.Empty();
	}
};

#endif