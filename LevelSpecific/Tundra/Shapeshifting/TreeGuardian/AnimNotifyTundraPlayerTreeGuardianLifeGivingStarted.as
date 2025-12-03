class UAnimNotifyTundraPlayerTreeGuardianLifeGivingStarted : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraTreeGuardianLifeGivingStarted";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		ATundraPlayerTreeGuardianActor TreeGuardian = Cast<ATundraPlayerTreeGuardianActor>(MeshComp.GetOwner());
		if(TreeGuardian == nullptr)
		{
			Print("WARNING: Life giving started anim notify not triggered, tree guardian was null!");
			return false;
		}

		UTreeGuardianBaseEffectEventHandler::Trigger_OnNonRangedLifeGivingHandsTouchEarth(TreeGuardian);
		return true;
	}
}