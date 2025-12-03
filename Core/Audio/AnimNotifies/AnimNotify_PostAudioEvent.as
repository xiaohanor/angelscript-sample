class UAnimNotify_PostAudioEvent : UAnimNotify
{
	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent Event = nullptr;

	UPROPERTY(EditInstanceOnly)
	FName AttachComponentName = NAME_None;

	UPROPERTY(EditInstanceOnly)
	bool bUseSkelMeshAsAttach = false;

	UPROPERTY(EditInstanceOnly, Meta = (ShowOnlyInnerProperties))
	FHazeAudioFireForgetEventParams Params;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Event == nullptr)
			return false;

		#if EDITOR
 			if(!Editor::IsPlaying())
			{
				FScopeDebugEditorWorld EditorWorld;
				AudioComponent::PostGlobalEvent(Event);			
				return true;	
			}
		#endif

		AActor Actor = MeshComp.GetOwner();
		auto EventParams = Params;

		if (bUseSkelMeshAsAttach)
		{
			EventParams.AttachComponent = MeshComp;
		}
		else
		{
			if(AttachComponentName != NAME_None)
			{
				EventParams.AttachComponent = USceneComponent::Get(Actor, AttachComponentName);
			}
			else
			{
				EventParams.AttachComponent = Actor.RootComponent;
			}
		}

		AudioComponent::PostFireForget(Event, EventParams);
		return true;
	}
}