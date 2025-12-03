class UAnimInstanceTundraSnapFlower : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Snap;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Closed;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Open;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Interact;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldSnap;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRandomStartTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldInteract;

	ASnapFlower SnapFlower;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		SnapFlower = Cast<ASnapFlower>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		bRandomStartTime = true;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SnapFlower == nullptr)
			return;

		bShouldSnap = SnapFlower.AnimData.ShouldSnap();
		bShouldInteract = SnapFlower.AnimData.ShouldInteract();
	}

	UFUNCTION()
	void AnimNotify_ResetRandomStartTime()
	{
		bRandomStartTime = false;
	}
}