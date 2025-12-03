class UPlayerSnowMonkeyIceKingBossPunchRootMotionAnimNotifyState : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowMonkeyBossPunchRootMotionState";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		if(!MeshComp.AttachmentRootActor.IsA(AHazePlayerCharacter))
			return false;

		auto BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(MeshComp.AttachmentRootActor);

		if(BossPunchComp == nullptr)
			return false;

		BossPunchComp.bWithinRootMotionState = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		if(!MeshComp.AttachmentRootActor.IsA(AHazePlayerCharacter))
			return false;
		
		auto BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(MeshComp.AttachmentRootActor);

		if(BossPunchComp == nullptr)
			return false;

		BossPunchComp.bWithinRootMotionState = false;
		return false;
	}
}