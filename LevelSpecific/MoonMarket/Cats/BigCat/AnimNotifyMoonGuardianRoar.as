class UAnimNotifyMoonGuardianRoar : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor::FromHex("F7E2D3FF");
#endif

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		AMoonGuardianCat MoonGuardian = Cast<AMoonGuardianCat>(MeshComp.Owner);

		MoonGuardian.Roar();
		
		return true;
	}
}

class UAnimNotifyMoonGuardianRoarStarted : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor::FromHex("F7E2D3FF");
#endif

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		AMoonGuardianCat MoonGuardian = Cast<AMoonGuardianCat>(MeshComp.Owner);

		UMoonGuardianCatEffectHandler::Trigger_OnCatRoarStarted(MoonGuardian);
		
		return true;
	}
}