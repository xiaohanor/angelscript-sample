class UBigCrackBirdPickupAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.AttachmentRootActor);
		if(Player == nullptr)
			return false;

		if(Player.IsMio())
			Player.PlayForceFeedback(ForceFeedback::Default_Heavy_Short, this);
		else
			Player.PlayForceFeedback(ForceFeedback::Default_Very_Light, this);

		return true;
	}
}

class UBigCrackBirdThrowAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		UBigCrackBirdCarryComponent CarryComp = UBigCrackBirdCarryComponent::Get(MeshComp.AttachmentRootActor);
		if(CarryComp == nullptr)
			return false;

		const float Intensity = CarryComp.CurrentBird.bIsEgg ? 0.7 : 1;

		ForceFeedback::PlayWorldForceFeedback(CarryComp.CurrentBird.ThrownInNestFeedback, CarryComp.CurrentBird.ActorLocation, false, this, Intensity = Intensity);
		return true;
	}
}