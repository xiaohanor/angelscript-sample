class ASolarFlareWeightedPerchSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisComp;

	UPROPERTY(DefaultComponent, Attach = AxisComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = AxisComp)
	UFauxPhysicsWeightComponent WeightLeft;
	default WeightLeft.MassScale = 0.0;

	UPROPERTY(DefaultComponent, Attach = AxisComp)
	UFauxPhysicsWeightComponent WeightRight;
	default WeightRight.MassScale = 0.0;

	UPROPERTY(EditAnywhere)
	APerchSpline PerchSpline;

	float MaxScale = 0.1;
	float SplineDistanceMidway;
	float DeadzoneRange = 0.05;

	TArray<AHazePlayerCharacter> ActivePlayers;

	float EqualOutWieghtTime;
	float EqualOutWieghtDuration = 0.75;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchSpline.AttachToComponent(AxisComp);
		PerchSpline.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerchingEvent");
		PerchSpline.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");
		SplineDistanceMidway = PerchSpline.Spline.SplineLength / 2.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		WeightRight.MassScale = 0.0;
		WeightLeft.MassScale = 0.0;
		float AverageAlpha = 0.0;

		TArray<float> WeightingAlpha;
		float Dot = AxisComp.RightVector.DotProduct(ActorRightVector);

		for (AHazePlayerCharacter Player : ActivePlayers)
		{
			float CurrentWeightAlpha = (GetPlayerDistanceAlongSpline(Player) - SplineDistanceMidway) / SplineDistanceMidway;

			if (CurrentWeightAlpha < DeadzoneRange && CurrentWeightAlpha > -DeadzoneRange)
				continue;

			WeightingAlpha.Add(CurrentWeightAlpha);
		}

		for (float Alpha : WeightingAlpha)
		{
			AverageAlpha += Alpha;

			//Multiply weight amount added per frame based on angle of the axis comp compared to their distance along the spline
			//Ensures that axis comp doesn't keep rotating indefinitely and weighs accurately compared to where the player's are on it
			float AlphaForDot = Math::Abs(Alpha / 1.75); 
			float Multiplier = AlphaForDot - (1.0 - Dot);
			
			if (Alpha > 0.0)
				WeightRight.MassScale += MaxScale * Multiplier;
			else
				WeightLeft.MassScale += MaxScale * Multiplier;
		}

		if (WeightingAlpha.Num() == 0 && Time::GameTimeSeconds > EqualOutWieghtTime)
		{
			WeightRight.MassScale = MaxScale;
			WeightLeft.MassScale = MaxScale;
		}	


		if (Math::Abs(Dot) < 0.8)
		{
			if (!PerchSpline.IsActorDisabledBy(this))
			{
				MeshComp.RemoveTag(n"Walkable");
				PerchSpline.AddActorDisable(this);	
				EqualOutWieghtTime = Time::GameTimeSeconds + EqualOutWieghtDuration;
			}
		}
		else /*if (Math::Abs(Dot) < 0.85)*/
		{
			if (PerchSpline.IsActorDisabledBy(this))
			{
				MeshComp.AddTag(n"Walkable");
				PerchSpline.RemoveActorDisable(this);	
			}
		}
	}

	UFUNCTION()
	private void OnPlayerStartedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		ActivePlayers.AddUnique(Player);
	}

	UFUNCTION()
	private void OnPlayerStoppedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		ActivePlayers.Remove(Player);
	}

	float GetPlayerDistanceAlongSpline(AHazePlayerCharacter Player)
	{
		return PerchSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
	}
}