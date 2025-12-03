class UAnimNotify_DanceShowdownThrowableMonkeySlamLeft : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Cast<ADanceShowdownThrowableMonkey>(MeshComp.Owner) == nullptr)
			return false;

		Cast<ADanceShowdownThrowableMonkey>(MeshComp.Owner).PlayForceFeedback(false);
		return true;
	}
}

class UAnimNotify_DanceShowdownThrowableMonkeySlamRight : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Cast<ADanceShowdownThrowableMonkey>(MeshComp.Owner) == nullptr)
			return false;

		Cast<ADanceShowdownThrowableMonkey>(MeshComp.Owner).PlayForceFeedback(true);
		return true;
	}
}