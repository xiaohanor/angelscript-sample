class UAnimInstanceSketchBookSimpleEnemy : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlayRate;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		PlayRate = 0;

		USketchbookDrawableComponent DrawComp = USketchbookDrawableComponent::Get(HazeOwningActor);
		if (DrawComp == nullptr)
		{
			PlayRate = 1;
			return;
		}

		if (DrawComp.IsDrawnOrBeingDrawn())
			PlayRate = 1;
		else
			DrawComp.OnStartBeingDrawn.AddUFunction(this, n"OnBeingDrawn");
	}

	UFUNCTION()
	void OnBeingDrawn()
	{
		ASketchbookSimpleEnemy SimpleEnemy = Cast<ASketchbookSimpleEnemy>(HazeOwningActor);
		const float AnimDelay = SimpleEnemy != nullptr ? SimpleEnemy.AnimationDelay : 0.3;

		Timer::SetTimer(this, n"StartAnimating", AnimDelay);
	}

	UFUNCTION()
	void StartAnimating()
	{
		PlayRate = 1;
	}
}