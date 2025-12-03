class UAnimNotifyStatePlayerLookAtAlpha : UAnimNotifyState
{

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Alpha = 0;

#if EDITOR
	default NotifyColor = FColor::Emerald;
#endif


	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Look At Alpha";
	}


	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		auto LookAtComponent = UHazeAnimPlayerLookAtComponent::Get(MeshComp.Owner);
		if (LookAtComponent != nullptr) 
		{
			LookAtComponent.SetCustomLookAtAlpha(this, Alpha);
		}
		
		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;
		
		auto LookAtComponent = UHazeAnimPlayerLookAtComponent::Get(MeshComp.Owner);
		if (LookAtComponent != nullptr) 
		{
			LookAtComponent.ClearCustomLookAtAlpha(this);
		}

		return true;
	}
}