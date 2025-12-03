
class UAnimInstanceTundraChompFlower : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Bite;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BiteSuccess;

	// Add Custom Variables Here

	ATundraCrackSpringLogNyparn Nyparn;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LocomotionBlendSpaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BlendSpaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccess = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIdle = true;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		Nyparn = Cast<ATundraCrackSpringLogNyparn>(HazeOwningActor);
	}

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Nyparn == nullptr)
			return;

		LocomotionBlendSpaceValue = Nyparn.AnimData.SpeedAlpha;
		BlendSpaceValue = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(-1.0, 1.0), Nyparn.AnimData.CloseAlpha);
		bSuccess = Nyparn.AnimData.bAttachedToLog;
		bIdle = BlendSpaceValue	== -1.0;
    }
}