class UAnimNotifyTundraPlayerTreeGuardianFootstep : UAnimNotify
{
	UPROPERTY(EditAnywhere)
	bool bIsLeft = true;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraTreeGuardianFootstep";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		ATundraPlayerTreeGuardianActor TreeGuardian = Cast<ATundraPlayerTreeGuardianActor>(MeshComp.GetOwner());
		if(TreeGuardian == nullptr)
		{
			Print("WARNING: TreeGuardianFootstep anim notify not triggered, tree guardian was null!");
			return false;
		}

		TreeGuardian.StepComponent.bIsLeft = !bIsLeft;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnFootstep(TreeGuardian, FTundraPlayerTreeGuardianOnFootstepParams(bIsLeft));
		return true;
	}
}