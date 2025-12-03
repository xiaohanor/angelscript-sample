class UAnimNotify_PunchotronSkatingLeft : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "PunchotronSkatingLeft";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(MeshComp.Owner);
		if(Punchotron == nullptr)
			return true;

		UIslandPunchotronEffectHandler::Trigger_OnSkateLeftStart(Punchotron, FIslandPunchotronSingleJetParams(Punchotron.LeftJetLocation));

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(MeshComp.Owner);
		if(Punchotron == nullptr)
			return true;
		
		UIslandPunchotronEffectHandler::Trigger_OnSkateLeftEnd(Punchotron);
		
		return true;
	}
}


class UAnimNotify_PunchotronSkatingRight : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "PunchotronSkatingRight";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(MeshComp.Owner);
		if(Punchotron == nullptr)
			return true;

		UIslandPunchotronEffectHandler::Trigger_OnSkateRightStart(Punchotron, FIslandPunchotronSingleJetParams(Punchotron.RightJetLocation));

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(MeshComp.Owner);
		if(Punchotron == nullptr)
			return true;

		UIslandPunchotronEffectHandler::Trigger_OnSkateRightEnd(Punchotron);

		return true;
	}
}

