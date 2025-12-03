UCLASS(Abstract)
class UGameplay_Explosion_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	

	FHazeTraceSettings Trace;
	default Trace.SetReturnPhysMaterial(true);
	private TMap<FName, UHazeAudioEvent> CachedEvents;

	UFUNCTION(BlueprintPure)
	bool GetPhysMatFromSphereTrace(const float TraceRadius, FVector& OutLocation, float& OutDistance, UPhysicalMaterialAudioAsset& OutAudioPhys)
	{	
		auto AudioComponent = DefaultEmitter.GetAudioComponent();
		
		float32 OutTraceDist = 0.0;
		UPhysicalMaterial PhysMat;
		const bool bHitPhysMat = AudioTrace::GetPhysMaterialFromSphereTrace(AudioComponent.GetWorldLocation(), TraceRadius, OutLocation, OutTraceDist, PhysMat);
		
		//PrintToScreenScaled("BoolInAS: " + bHitPhysMat, 1.0);
		//PrintToScreenScaled("PhysMat: " + PhysMat, 1.0);
		
		if(bHitPhysMat)
		{
			OutAudioPhys = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);	
			OutDistance = Math::GetMappedRangeValueClamped(FVector2D(0.0, TraceRadius), FVector2D(1.0, 0.0), OutTraceDist);		
		}		

		if(IsDebugging())
		{
			FName PhysMatName = OutAudioPhys != nullptr ? OutAudioPhys.GetName() : n"None";

			PrintToScreenScaled("Explosion Debris Phys Mat: " + PhysMatName, 2.0);
			PrintToScreenScaled("Debris Radius Distance: " + OutDistance, 2.0);
			Debug::DrawDebugSphere(AudioComponent.GetWorldLocation(), TraceRadius, Duration = 2.0);
		}		
		
		return bHitPhysMat;	
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetMaterialDebrisEvent(const FName MaterialTag, UHazeAudioEvent DefaultEvent)
	{
		UHazeAudioEvent FoundEvent;
		CachedEvents.Find(MaterialTag, FoundEvent);

		if(FoundEvent == nullptr)
		{
			FString EventName = f"Play_Explosion_Shared_Material_Debris_{MaterialTag}";
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
