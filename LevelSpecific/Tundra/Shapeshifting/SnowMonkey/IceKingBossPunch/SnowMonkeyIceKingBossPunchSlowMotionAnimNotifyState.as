class UTundraSnowMonkeyIceKingBossPunchSlowMotionAnimNotifyState : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowMonkeyBossPunchSlowMotion";
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

		if(!BossPunchComp.HasControl())
			return false;

		BossPunchComp.CrumbEnterSlowMotionWindow(TotalDuration);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		if(!MeshComp.AttachmentRootActor.IsA(AHazePlayerCharacter))
			return false;

		auto BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(MeshComp.AttachmentRootActor);

		if(BossPunchComp == nullptr)
			return false;

		return true;
	}
}