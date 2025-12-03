class UAnimInstanceTundraFlowerButton : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Hit;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bSmashedThisFrame;

	AMonkeySmasherForFairyLauncher MonkeySmasher;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor == nullptr)
			return;

		MonkeySmasher = Cast<AMonkeySmasherForFairyLauncher>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		bSmashedThisFrame = MonkeySmasher.AnimData.SmashedThisFrame();
	}
}