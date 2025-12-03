class UAnimNotify_Dentist_BossDenturesBiteEvent : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DentistBossDenturesBite";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Dentures = Cast<ADentistBossToolDentures>(MeshComp.Owner);
		if(Dentures == nullptr)
			return true;

		Dentures.TriggerBiteEvent();

		return true;
	}
}