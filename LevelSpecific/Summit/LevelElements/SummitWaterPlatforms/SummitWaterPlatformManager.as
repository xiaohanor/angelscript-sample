class ASummitWaterPlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineComp;
	default SplineComp.EditingSettings.HeightIndicators = ESplineHeightIndicatorMode::None;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	// Default speed on the spline when not overridden
	UPROPERTY(EditAnywhere)
	float DefaultSpeed = 25.0;

	// Acceleration when changing the speed of the platforms
	UPROPERTY(EditAnywhere)
	float Acceleration = 250.0;

	// How far platforms need to travel before they go back to the top
	UPROPERTY(EditAnywhere)
	float InvisibleDistance = 0.0;

	private TArray<ASummitWaterPlatform> Platforms;
	private TInstigated<float> Speed;
	private float CurrentSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Speed.SetDefaultValue(DefaultSpeed);
		CurrentSpeed = DefaultSpeed;
	}

	void AddWaterPlatform(ASummitWaterPlatform Platform)
	{
		Platforms.Add(Platform);
		Platform.Position = SplineComp.GetClosestSplinePositionToWorldLocation(Platform.ActorLocation);
		Platform.bOnSpline = true;
	}

	// Apply an override for the platform speed
	UFUNCTION(Category = "Summit Water Platform")
	void ApplyPlatformSpeed(float NewSpeed, FInstigator Instigator)
	{
		Speed.Apply(NewSpeed, Instigator);
	}

	// Clear a previous override for the platform speed
	UFUNCTION(Category = "Summit Water Platform")
	void ClearPlatformSpeed(FInstigator Instigator)
	{
		Speed.Clear(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, Speed.Get(), DeltaSeconds, Acceleration);
		float MoveDelta = DeltaSeconds * CurrentSpeed;

		for (auto Platform : Platforms)
		{
			if (Platform.bOnSpline)
			{
				bool bCouldMove = Platform.Position.Move(MoveDelta);
				if (!bCouldMove)
				{
					Platform.bOnSpline = false;
					Platform.InvisibleDistance = 0.0;
					Platform.AddActorDisable(this);
				}
				else
				{
					Platform.UpdatePositionOnSpline();
				}
			}
			else
			{
				Platform.InvisibleDistance += MoveDelta;
				if (Platform.InvisibleDistance >= InvisibleDistance)
				{
					Platform.bOnSpline = true;
					Platform.Position = SplineComp.GetSplinePositionAtSplineDistance(0.0);
					Platform.UpdatePositionOnSpline();
					Platform.RemoveActorDisable(this);
				}
			}
		}
	}
};