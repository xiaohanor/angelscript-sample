

class UAnimInstanceSummitGiantsPickUp : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PickUpEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData PickUpMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Climb;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ClimbMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StretchArm;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StretchArmMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StretchArmThrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeAcceleratedVector LookAtLocationHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LookAtLocationEyes;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LookAtAlpha;

	bool bClosest;

	UAnimGiantsLookAtComponent LookAtComp;
	bool bEnabled;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		LookAtComp = UAnimGiantsLookAtComponent::GetOrCreate(HazeOwningActor);
		bClosest = true;
		bEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LookAtComp == nullptr)
			return;

		if (GetAnimTrigger(n"LookAtDisable"))
		{
			bEnabled = false;
			bClosest = false;
		}
		else if (GetAnimTrigger(n"LookAtEnable"))
		{
			bEnabled = true;
		}

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(bClosest, LookAtLocationHead, LookAtLocationEyes, DeltaTime, Radius = 8500);
		LookAtAlpha = bHasValidTarget && bEnabled ? 1 : 0;
	}
}