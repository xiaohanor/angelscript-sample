class UAnimInstanceSketchBookCyclops : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHelmetOpen;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBlink;

	float BlinkTimer;

	ASketchbookCyclops Cyclops;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Cyclops = Cast<ASketchbookCyclops>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Cyclops == nullptr)
			return;

		bHelmetOpen = Cyclops.bHelmetOpen;

		BlinkTimer -= DeltaTime;
		if (BlinkTimer <= 0)
		{
			bBlink = true;
			BlinkTimer = Math::RandRange(0.5, 8);
		}
		else
			bBlink = false;

	}
}