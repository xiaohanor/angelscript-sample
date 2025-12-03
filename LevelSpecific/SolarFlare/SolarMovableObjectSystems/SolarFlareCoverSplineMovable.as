enum ESolarFlareCoverSplineMovementMode
{
	Stick,
	Mash,
	Hold
}

enum ESolarFlareCoverSplineMovementDirection
{
	Forwards,
	Backwards
}

enum ESolarFlareCoverSplineInputReadAxis
{
	XAxis,
	YAxis
}

class ASolarFlareCoverSplineMovable : AHazeActor
{
	UPROPERTY(EditAnywhere)
	ESolarFlareCoverSplineMovementDirection SolarFlareCoverSplineMovementDirection;

	UPROPERTY(EditAnywhere)
	ESolarFlareCoverSplineMovementMode Mode;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(EditAnywhere, meta = (EditCondition = "Mode == ESolarFlareCoverSplineMovementMode::Stick", EditConditionHides))
	ESolarFlareCoverSplineInputReadAxis SolarFlareCoverSplineInputReadAxis;

	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> TargetActors;

	UPROPERTY(EditAnywhere)
	bool bRequiresPump = false;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bRequiresPump", EditConditionHides))
	ASolarFlarePumpInteraction PumpInteraction;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float ForceAmount = 500.0;

	UPROPERTY(EditAnywhere)
	float Acceleration = 15800.0;

	UPROPERTY(EditAnywhere)
	float Decceleration = 2000.0;

	FSplinePosition SplinePos;

	float ForceTarget;
	float Force;
	
	float Multiplier = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePos = SplineActor.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);

		switch (Mode)
		{
			case ESolarFlareCoverSplineMovementMode::Stick:
				for (AHazeActor Target : TargetActors)
					Cast<ASolarFlareStickInteraction>(Target).OnSolarFlareMovementStickApplied.AddUFunction(this, n"OnSolarFlareMovementStickApplied");
				break;
			case ESolarFlareCoverSplineMovementMode::Mash:
				for (AHazeActor Target : TargetActors)
					Cast<ASolarFlarePumpInteraction>(Target).OnButtonMashApplied.AddUFunction(this, n"OnButtonMashApplied");
				break;
			case ESolarFlareCoverSplineMovementMode::Hold:
				break;
		}
	}

	UFUNCTION()
	private void OnSolarFlareMovementStickApplied(FVector2D Input)
	{
		if (SolarFlareCoverSplineInputReadAxis == ESolarFlareCoverSplineInputReadAxis::XAxis)
			ForceTarget = Input.X;
		else
			ForceTarget = Input.Y;
	}

	UFUNCTION()
	private void OnButtonMashApplied(float Progress)
	{
		ForceTarget = Progress;
	}

	UFUNCTION()
	void SetMultiplier(float NewMultiplier)
	{
		Multiplier = NewMultiplier;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float InterpSpeed = 0.0;
		
		if (ForceTarget != 0.0)
			InterpSpeed = Acceleration;
		else
			InterpSpeed = Decceleration;

		if (bRequiresPump)
		{
			if (PumpInteraction.ButtonMashComp != nullptr)
				Multiplier = PumpInteraction.ButtonMashComp.GetButtonMashProgress(PumpInteraction);
			else
				Multiplier = 0.0;
		}

		float FinalTarget = ForceTarget * ForceAmount * Multiplier;

		if (SolarFlareCoverSplineMovementDirection == ESolarFlareCoverSplineMovementDirection::Backwards)
			FinalTarget *= -1.0;

		Force = Math::FInterpConstantTo(Force, FinalTarget, DeltaSeconds, InterpSpeed);
		
		if (Force != 0.0)
			PrintToScreen("Force: " + Force);

		SplinePos.Move(Force * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;
		ForceTarget = 0.0;
	}
}