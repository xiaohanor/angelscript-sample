
class UBasicAIVoiceOverManager : UHazeSingleton
{
	TMap<TWeakObjectPtr<UClass>, int> NextVoiceIDMap;

	uint NumGeneratedIds = 0; // Currently not in use.
	
	void CreateNewVoiceID(TWeakObjectPtr<UClass> Type, int& OutVoiceID)
	{
		check(Type.IsValid());
		if (!NextVoiceIDMap.Contains(Type))
			NextVoiceIDMap.Add(Type, 0);
		OutVoiceID = NextVoiceIDMap[Type];
		NextVoiceIDMap[Type]++;
		NumGeneratedIds++;
	}

	// Clear map on loading screens.
	UFUNCTION(BlueprintOverride)
	void ResetStateBetweenLevels()
	{
		NextVoiceIDMap.Empty();
	}
}
