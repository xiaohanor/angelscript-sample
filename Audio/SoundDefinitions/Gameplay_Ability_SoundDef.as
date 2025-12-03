
struct FAbilityShootParams
{
	UPROPERTY()
	float Intensity;
}

UCLASS(Abstract)
class UGameplay_Ability_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityActivated(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityStartCharging(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityFullyCharged(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityShoot(FAbilityShootParams AbilityShootParams){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityLoopStopped(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityStopChargeUp(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityAbortChargeUp(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnAbilityForceImpact(FAudioForceImpactParams AudioForceImpactParams){}

	/* END OF AUTO-GENERATED CODE */
	
	UPROPERTY(BlueprintReadOnly, Category = "Global")
	AHazePlayerCharacter AbilityPlayerOwner;
	private TMap<FName, UHazeAudioEvent> CachedEvents;

	// Set from adapters
	float ChargeFraction;

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetMaterialDebrisEvent(const FName MaterialTag, UHazeAudioEvent DefaultEvent)
	{
		UHazeAudioEvent FoundEvent;
		CachedEvents.Find(MaterialTag, FoundEvent);

		if(FoundEvent == nullptr)
		{
			FString EventName = f"Play_Ability_Blast_Shared_Material_Debris_{MaterialTag}";
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

	UFUNCTION(BlueprintPure)
	float GetChargeFraction()
	{
		return ChargeFraction;
	}
}