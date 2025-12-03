class UAnimNotify_GiantsAudio : UAnimNotify
{
	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent Event = nullptr;

	UPROPERTY(EditInstanceOnly, Meta = (GetOptions = "GetBoneNames"))
	FName BoneAttach = NAME_None;

	UPROPERTY(EditInstanceOnly)
	float AttenuationScaling = 15000;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp == nullptr)
			return false;

		if(Event == nullptr)
			return false;
		
		#if EDITOR
 			if(!Editor::IsPlaying())
			{
				FScopeDebugEditorWorld EditorWorld;
				AudioComponent::PostGlobalEvent(Event);				
			}
		#endif

		ATheGiant Giant = Cast<ATheGiant>(MeshComp.Outer);
		if(Giant == nullptr)
			return false;	

		Giant.PlayAudioOnSocket(Event, AttenuationScaling, BoneAttach);

		#if EDITOR
			Giant.AnimNotifyToEventDebugMap.FindOrAdd(Event.GetName(), Animation.GetName());
		#endif

		return true;
	}	

#if EDITOR
	UFUNCTION()
	TArray<FString> GetBoneNames() const
	{
		TArray<FString> BoneNames;

		auto SocketNames = GiantsAudio::GetSocketNames();
		for(auto& BoneName : SocketNames)
		{
			BoneNames.Add(BoneName.ToString());
		}

		return BoneNames;
	}
#endif
}