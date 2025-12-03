class UMoonMarketMushroomPeopleStepAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		AMushroomPeople Mushroom = Cast<AMushroomPeople>(MeshComp.Owner);
		if(Mushroom == nullptr)
			return false;

		UMoonMarketMushroomPeopleEventHandler::Trigger_OnStep(Mushroom);
		return true;
	}
}