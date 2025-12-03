
class UAnimInstanceSummitGiantsHelpAcrossGap : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HelpAcrossGapEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HelpAcrossGapMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HelpAcrossGapStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HelpAcrossGapStartMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HelpAcrossGapExit;

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

		if (GetAnimTrigger(n"LookAtEnable"))
			bEnabled = true;

		if (GetAnimTrigger(n"LookAtDisable"))
			bEnabled = false;

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(true, LookAtLocationHead, LookAtLocationEyes, DeltaTime);
		LookAtAlpha = bHasValidTarget && bEnabled ? 1 : 0;
	}
}