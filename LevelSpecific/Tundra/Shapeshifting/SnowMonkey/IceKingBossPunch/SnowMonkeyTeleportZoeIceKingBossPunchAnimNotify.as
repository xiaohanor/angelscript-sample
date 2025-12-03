class USnowMonkeyTeleportZoeIceKingBossPunchAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TeleportZoeIceKingBossPunch";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(!MeshComp.AttachmentRootActor.IsA(AHazePlayerCharacter))
			return false;

		auto Comp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(MeshComp.AttachmentRootActor);
		
		if(Comp == nullptr)
			return false;

		if(Comp.CurrentBossPunchInteractionActor == nullptr)
			return false;

		Comp.CurrentBossPunchInteractionActor.OnTeleportZoeNotify.Broadcast();

		return true;
	}
}