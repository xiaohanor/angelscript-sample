class UAnimNotify_PostPlayerAudioEvent : UAnimNotify
{
	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent MioEvent = nullptr;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent ZoeEvent = nullptr;

	UPROPERTY(EditInstanceOnly)
	FName AttachComponentName = NAME_None;

	UPROPERTY(EditInstanceOnly, Meta = (ShowOnlyInnerProperties))
	FHazeAudioFireForgetEventParams Params;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		#if EDITOR
 			if(!Editor::IsPlaying())
			{
				UHazeAudioEvent DebugEvent = MioEvent;
				if(DebugEvent == nullptr)
					DebugEvent = ZoeEvent;

				if(DebugEvent == nullptr)
					return false;

				FScopeDebugEditorWorld EditorWorld;
				AudioComponent::PostGlobalEvent(DebugEvent);			
				return true;	
			}

		#endif

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.GetOwner());
		if(Player == nullptr)
			return false;

		UHazeAudioEvent PlayerEvent = Player.IsMio() ? MioEvent : ZoeEvent;
		if(PlayerEvent == nullptr)
			return false;

		auto EventParams = Params;

		if(AttachComponentName != NAME_None)
		{
			EventParams.AttachComponent = USceneComponent::Get(Player, AttachComponentName);
		}
		else
		{
			EventParams.AttachComponent = Player.RootComponent;
		}

		AudioComponent::PostFireForget(PlayerEvent, EventParams);
		return true;
	}
}
