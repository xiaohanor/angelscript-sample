
class UAnimInstanceSummitGiantsNewYorkHanging : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HangingEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HangingMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HangingReach;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HangingReachMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FHazeAcceleratedVector LookAtLocationHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FVector LookAtLocationEyes;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	float LookAtAlpha = 0;

	UAnimGiantsLookAtComponent LookAtComp;
	bool bEnabled;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		LookAtComp = UAnimGiantsLookAtComponent::GetOrCreate(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LookAtComp == nullptr)
			return;

		if (!bEnabled && GetAnimTrigger(n"LookAtEnable"))
			bEnabled = true;

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(false, LookAtLocationHead, LookAtLocationEyes, DeltaTime);
		LookAtAlpha = bHasValidTarget && bEnabled ? 1 : 0;
	}
}