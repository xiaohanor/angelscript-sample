
UCLASS(Abstract)
class UCharacter_Boss_Sanctuary_Hydra_Vocalizations_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnTriggerVocalization(FSanctuaryBossMedallionManagerHydraVocalizationData NewData){}

	/* END OF AUTO-GENERATED CODE */

	TMap<AHazeActor, UHazeAudioEmitter> HydraVocalizationEmitters;

	UPROPERTY(BlueprintReadWrite)
	float AttenuationScaling = 25000;

	UFUNCTION(BlueprintPure)
	void GetHydraVocalizationEmitter(ASanctuaryBossMedallionHydra Hydra, UHazeAudioEmitter&out Emitter)
	{
		if(!HydraVocalizationEmitters.Find(Hydra, Emitter))
		{
			FHazeAudioEmitterAttachmentParams AttachParams;
			AttachParams.Attachment = Hydra.SkeletalMesh;
			AttachParams.BoneName = n"LaserSocket";
			AttachParams.Instigator = this;
			AttachParams.Owner = Hydra;
			AttachParams.bCanAttach = true;

			Emitter = Audio::GetPooledEmitter(AttachParams);
			Emitter.SetAttenuationScaling(AttenuationScaling);
			
			HydraVocalizationEmitters.Add(Hydra, Emitter);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto& Elem : HydraVocalizationEmitters)
		{
			UHazeAudioEmitter PooledEmitter = Elem.Value;
			Audio::ReturnPooledEmitter(this, PooledEmitter);
		}
	}
}