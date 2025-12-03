class UAnimInstanceSkylineWhipBird : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Lift;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Fly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Grabbed;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Thrown;
	
	ASkylineWhipBird WhipBird;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFlying = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSitting = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanding = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLifting = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsThrown = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrabbed = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
			WhipBird = Cast<ASkylineWhipBird>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		bIsFlying = WhipBird.bIsFlying;
		bIsSitting = WhipBird.bIsSitting;
		bIsLanding = WhipBird.bIsLanding;
		bIsLifting = WhipBird.bIsLifting;
		bIsThrown = WhipBird.bIsThrown;
		bIsGrabbed = WhipBird.WhipResponseComp.IsGrabbed();
	}
}