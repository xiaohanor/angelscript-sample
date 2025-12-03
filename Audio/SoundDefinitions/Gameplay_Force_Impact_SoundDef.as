struct FAudioForceImpactParams
{
	UPROPERTY()
	float Intensity = 0.0;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;
}


UCLASS(Abstract)
class UGameplay_Force_Impact_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	private TMap<FName, UHazeAudioEvent> CachedEvents;

	UPROPERTY(Category = "Event Assets")
	TArray<UHazeAudioEvent> MaterialEvents;

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetMaterialImpactEvent(const FName MaterialTag, UHazeAudioEvent DefaultEvent)
	{
		UHazeAudioEvent FoundEvent;
		CachedEvents.Find(MaterialTag, FoundEvent);

		if(FoundEvent == nullptr)
		{
			FString EventName = f"Play_Force_Shared_Impact_{MaterialTag}";
			if(Audio::GetAudioEventAssetByName(FName(EventName), FoundEvent))
			{
				CachedEvents.Add(MaterialTag, FoundEvent);
			}
			else
			{
				FoundEvent = DefaultEvent;
			}
		}

		return FoundEvent;
	}

}