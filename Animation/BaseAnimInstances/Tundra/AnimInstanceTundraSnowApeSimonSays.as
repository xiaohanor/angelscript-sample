class UAnimInstanceTundraSnowApeSimonSays : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Landing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TurnRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitJumpTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TempoMultiplier = 1;

	ATundra_SimonSaysMonkey Monkey;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		Monkey = Cast<ATundra_SimonSaysMonkey>(HazeOwningActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(HazeOwningActor == nullptr)
			return;

		bIsJumping = Monkey.AnimData.bIsJumping;
		TurnRate = Monkey.AnimData.TurnRate;
		ExplicitJumpTime = Monkey.AnimData.JumpAlpha;
		TempoMultiplier = Monkey.AnimData.TempoMultiplier;
	}
}