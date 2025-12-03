class UAnimNotifyGravityWhipHitWindow : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Hit Data")
	EAnimHitPitch HitPitch = EAnimHitPitch::Center;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Forward;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	float KnockbackMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	float KnockbackExtraDistance = 1.0;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GravityWhipHitWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		UGravityWhipUserComponent WhipComp = UGravityWhipUserComponent::Get(MeshComp.Owner);
		if (WhipComp == nullptr)
			return true;

		WhipComp.bInsideHitWindow = true;
		WhipComp.HitWindowPushbackMultiplier = KnockbackMultiplier;
		WhipComp.HitWindowExtraPushback = KnockbackExtraDistance;
		WhipComp.HitPitch = HitPitch;
		WhipComp.HitDirection = HitDirection;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		UGravityWhipUserComponent WhipComp = UGravityWhipUserComponent::Get(MeshComp.Owner);
		if (WhipComp == nullptr)
			return true;

		WhipComp.bInsideHitWindow = false;

		return true;
	}
}