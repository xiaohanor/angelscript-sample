class UAnimInstanceSketchBookPrinceFalling : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Hanging")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Hanging")
	FHazePlaySequenceData Help;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Hanging")
	FHazePlaySequenceData HitLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Hanging")
	FHazePlaySequenceData HitRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fall")
	FHazePlaySequenceData Fall;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fall")
	FHazePlaySequenceData Landing;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fall")
	FHazePlaySequenceData LandingMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLanded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHelp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitByArrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShotDown;

	float HelpTime;

	ASketchBookPrinceFalling PrinceFalling;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		PrinceFalling = Cast<ASketchBookPrinceFalling>(HazeOwningActor);
		if (PrinceFalling != nullptr &&
			PrinceFalling.AttachParentActor != nullptr &&
			PrinceFalling.AttachParentActor.AttachParentActor != nullptr)
		{
			auto MovingActor = Cast<AKineticMovingActor>(PrinceFalling.AttachParentActor.AttachParentActor);
			MovingActor.OnReachedForward.AddUFunction(this, n"OnReachedBottom");
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (PrinceFalling == nullptr)
			return;

		bLanded = GetAnimTrigger(n"Landed");
		bShotDown = GetAnimTrigger(n"ShotDown");

		if (GetAnimTrigger(n"CallForHelp"))
		{
			HelpTime = 2.8;
			bHelp = true;
		}
		else if (bHelp)
		{
			HelpTime -= DeltaTime;
			if (HelpTime <= 0)
				bHelp = false;
		}

		bHitByArrow = GetAnimTrigger(n"Hit");
		if (bHitByArrow)
		{
			bHitLeft = GetAnimTrigger(n"HitLeft");
			HelpTime = 0;
		}
	}

	UFUNCTION()
	void OnReachedBottom()
	{
		// Set an anim param because this might be called while threaded
		SetAnimTrigger(n"CallForHelp");
	}
}