class UMoonMarketMoleStepAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		AMoonMarketMole Mole = Cast<AMoonMarketMole>(MeshComp.Owner);
		if(Mole == nullptr)
			return false;

		UMoonMarketMoleEventHandler::Trigger_OnStep(Mole);
		return true;
	}
}