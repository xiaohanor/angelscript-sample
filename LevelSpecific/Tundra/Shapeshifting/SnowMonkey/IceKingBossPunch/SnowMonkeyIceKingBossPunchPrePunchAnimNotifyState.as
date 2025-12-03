class UTundraSnowMonkeyIceKingBossPunchPrePunchAnimNotifyState : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowMonkeyBossPunchPrePunchState";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.AttachmentRootActor == nullptr)
			return false;

		if(!MeshComp.AttachmentRootActor.IsA(AHazePlayerCharacter))
			return false;

		auto BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(MeshComp.AttachmentRootActor);

		if(BossPunchComp == nullptr)
			return false;

		if(BossPunchComp.bWithinPrePunchWindow)
			return false;

		BossPunchComp.bWithinPrePunchWindow = true;
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

		if(!BossPunchComp.bWithinPrePunchWindow)
			return false;

		BossPunchComp.bWithinPrePunchWindow = false;
		BossPunchComp.OnPunch.Broadcast();
		return false;
	}
}

class UTundraSnowMonkeyIceKingBossPunchDealDamageAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowMonkeyBossPunchDealDamage";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		auto BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(MeshComp.AttachmentRootActor);

		if(BossPunchComp == nullptr)
			return false;

		if(!BossPunchComp.bWithinPrePunchWindow)
			return false;

		BossPunchComp.OnDealDamagePunch.Broadcast();
		return true;
	}
}