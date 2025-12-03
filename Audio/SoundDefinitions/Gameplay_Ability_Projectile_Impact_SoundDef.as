UCLASS(Abstract)
class UGameplay_Ability_Projectile_Impact_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	FHazeTraceSettings Trace;
	private TMap<FName, UHazeAudioEvent> CachedEvents;

	UFUNCTION(BlueprintPure)
	UPhysicalMaterialAudioAsset GetAudioPhysMatFromLocation()
	{
		Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);

		auto AudioComponent = DefaultEmitter.GetAudioComponent();
		
		UPhysicalMaterialAudioAsset AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(UPhysicalMaterialAudioAsset.DefaultObject);
		UPhysicalMaterial PhysMat = AudioTrace::GetPhysMaterialFromLocation(AudioComponent.GetWorldLocation(), AudioComponent.UpVector.GetSafeNormal(), Trace);

		if(PhysMat != nullptr)		
			AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);		

		return AudioPhysMat;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetMaterialDebrisEvent(const FName MaterialTag, UHazeAudioEvent DefaultEvent)
	{
		UHazeAudioEvent FoundEvent;
		CachedEvents.Find(MaterialTag, FoundEvent);

		if(FoundEvent == nullptr)
		{
			FString EventName = f"Play_Ability_Projectile_Shared_Material_Impact_Debris_{MaterialTag}";
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