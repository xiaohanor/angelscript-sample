class UAnimNotify_Dentist_BossToolSwap : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	EDentistBossTool FirstTool;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EDentistBossTool SecondTool;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DentistBossToolSwap";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		Dentist.SwapToolReferences(FirstTool, SecondTool);
		return true;
	}
}