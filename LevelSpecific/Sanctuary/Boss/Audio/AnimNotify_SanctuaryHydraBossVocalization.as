class UAnimNotify_SanctuaryHydraBossVocalization : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Hydra Vocalization";
	}

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent VocalizationEvent;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "VocalizationEvent != nullptr", EditConditionHides))
	bool bPreviewVocalizationEvent = false;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(VocalizationEvent == nullptr)
			return false;

		#if EDITOR
			if(bPreviewVocalizationEvent && !Editor::IsPlaying())
			{
				FScopeDebugEditorWorld EditorWorld;
				AudioComponent::PostGlobalEvent(VocalizationEvent);			
				return true;	
			}
		#endif

		ASanctuaryBossMedallionHydra MedallionHydra = Cast<ASanctuaryBossMedallionHydra>(MeshComp.GetOwner());	
		ASanctuary_Skydive_Hydra SkydiveHydra = Cast<ASanctuary_Skydive_Hydra>(MeshComp.GetOwner());	
		if(MedallionHydra != nullptr)
		{
			FSanctuaryBossMedallionManagerHydraVocalizationData Params;
			Params.Hydra = MedallionHydra;	
			Params.HydraType = MedallionHydra != nullptr ? MedallionHydra.HydraType : EMedallionHydra::MioLeft;
			Params.VocalizationEvent = VocalizationEvent;	

			UMedallionHydraAttackManagerEventHandler::Trigger_OnTriggerVocalization(MedallionHydra.Refs.HydraAttackManager, Params);		
			return true;	
		}
		else if(SkydiveHydra != nullptr)
		{
			FHazeAudioFireForgetEventParams Params;
			Params.AttachComponent = USceneComponent::Get(SkydiveHydra, n"SceneAudio");
			Params.AttenuationScaling = 50000;
			Params.bUseReverb = true;

			AudioComponent::PostFireForget(VocalizationEvent, Params);
			return true;
		}

		return false;

	}
}