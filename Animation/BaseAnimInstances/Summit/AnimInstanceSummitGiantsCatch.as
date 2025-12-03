
class UAnimInstanceSummitGiantsCatch : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData MhRelaxed;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Catch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData CatchMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData CatchTransport;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData CatchTransportMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FHazeAcceleratedVector LookAtLocationHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FVector LookAtLocationEyes;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	float LookAtAlpha = 0;

	UAnimGiantsLookAtComponent LookAtComp;

	bool bEnabled;
	bool bClosest;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		LookAtComp = UAnimGiantsLookAtComponent::GetOrCreate(HazeOwningActor);
		bClosest = true;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LookAtComp == nullptr)
			return;

		if (GetAnimTrigger(n"LookAtEnable"))
			bEnabled = true;

		if (GetAnimTrigger(n"LookAtDisable"))
		{
			bEnabled = false;
			bClosest = false;
		}

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(bClosest, LookAtLocationHead, LookAtLocationEyes, DeltaTime, Radius = 8000, ClampPitchMin = -10);
		LookAtAlpha = bEnabled && bHasValidTarget ? 1 : 0;
	}
}