class UAniminstanceDentistRevealCutscene : UHazeAnimInstanceBase
{

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator EyeRotationLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator EyeRotationRight;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		EyeRotationLeft.Roll -= DeltaTime * 150;
		EyeRotationRight.Roll += DeltaTime * 200;
	}
}