class ASanctuaryCentipedeSwingingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCentipedeProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotPivotComp;

	UPROPERTY(DefaultComponent, Attach = RotPivotComp)
	USceneComponent PlatformLocationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformPivotComp;

	UPROPERTY()
	FHazeTimeLike SwingTimeLike;
	default SwingTimeLike.bFlipFlop = true;

	int SuccessfulImpacts = 0;

	float SwingRotation = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleImpact");
		SwingTimeLike.BindUpdate(this, n"SwingTimeLikeUpdate");
	}

	UFUNCTION()
	void SwingTimeLikeUpdate(float Alpha)
	{
		float NewRot = Math::Lerp(SwingRotation * -1, SwingRotation, Alpha);
		RotPivotComp.SetRelativeRotation(FRotator(0.0, 0.0, NewRot));
		PrintToScreen("Rotation: " + NewRot);
		PrintToScreen("SwingRotation: " + SwingRotation);
	}

	UFUNCTION(DevFunction)
	void CallImpact()
	{
		Print("" + SwingTimeLike.IsReversed(), 5.0);
		Impact();
	}

	UFUNCTION()
	private void HandleImpact(FVector ImpactDirection, float Force)
	{
		Impact();
	}

	UFUNCTION()
	private void Impact()
	{
		if (SuccessfulImpacts == 0)
		{
			SwingTimeLike.SetNewTime(0.5);
			SuccessfulImpacts++;
			SwingTimeLike.Play();
		}

		else if (!SwingTimeLike.IsReversed())
		{
			if (SuccessfulImpacts < 3)
				SuccessfulImpacts++;
		}

		else if (SuccessfulImpacts > 0)
			SuccessfulImpacts--;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SwingRotation = Math::Lerp(SwingRotation, SuccessfulImpacts * 20.0, 2.0 * DeltaSeconds);
		PlatformPivotComp.SetWorldLocation(PlatformLocationComp.WorldLocation);
	}
};