class UAnimInstanceSketchbookBow : UHazeAnimInstanceBase
{
	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	FHazePlayBlendSpaceData Aim;

	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	FHazePlaySequenceData Shoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Charge;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUpdatePose;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bForceExit;

	bool bIsFiring;

	USketchbookBowPlayerComponent BowComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		BowComp = USketchbookBowPlayerComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (BowComp == nullptr)
			return;

		bAim = BowComp.IsAiming();
		Charge = BowComp.GetChargeFactor();

		bShoot = CheckValueChangedAndSetBool(bIsFiring, BowComp.IsFiring(), EHazeCheckBooleanChangedDirection::FalseToTrue);
		bUpdatePose = bShoot;

		bForceExit = GetAnimTrigger(n"Exit");
	}
}