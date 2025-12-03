class AIslandStormdrainSwingRail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USwingPointComponent Swing;

	UPROPERTY(EditInstanceOnly)
	APropLine PropLine;

	UPROPERTY(EditInstanceOnly)
	float HeightOffset = -50;

	UPROPERTY(EditInstanceOnly)
	float Acceleration = 400;

	UPROPERTY(EditInstanceOnly)
	float MaxSpeed = 1500;

	UPROPERTY(EditInstanceOnly)
	float MinSpeed = 400;

	UPROPERTY(EditInstanceOnly)
	bool bUpdateRotation = false;

	float Speed = 0;
	bool bIsAttached = false;
	TArray<AHazePlayerCharacter> AttachedPlayers;
	float DistanceAlongSpline = 0;
	float MaxDistanceAlongSpline = 0;

	default PrimaryActorTick.bStartWithTickEnabled = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(PropLine != nullptr)
		{
			FSplinePosition SplinePos = Spline::GetGameplaySpline(PropLine).GetSplinePositionAtSplineDistance(0);
			SetActorLocation(SplinePos.GetWorldLocation() + FVector(0, 0, HeightOffset));

			if (bUpdateRotation)
				UpdateRotation(SplinePos);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Swing.OnPlayerAttachedEvent.AddUFunction(this, n"HandlePlayerAttachToSwing");
		Swing.OnPlayerDetachedEvent.AddUFunction(this, n"HandlePlayerDetachFromSwing");
		MaxDistanceAlongSpline = Spline::GetGameplaySpline(PropLine).GetSplineLength();
	}

	UFUNCTION()
	void EnableSwing()
	{
		Swing.EnableAfterStartDisabled();
	}

	UFUNCTION()
	void HandlePlayerAttachToSwing(AHazePlayerCharacter Player, USwingPointComponent SwingComp)
	{
		AttachedPlayers.AddUnique(Player);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void HandlePlayerDetachFromSwing(AHazePlayerCharacter Player, USwingPointComponent SwingComp)
	{
		AttachedPlayers.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(AttachedPlayers.Num() <= 0)
		{
			if(DistanceAlongSpline <= 0)
			{
				SetActorTickEnabled(false);
			}

			else
			{
				Speed -= Acceleration*DeltaSeconds;
				Speed = Math::Clamp(Speed, -MinSpeed, -MaxSpeed);

				DistanceAlongSpline += Speed*DeltaSeconds;
				DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0, MaxDistanceAlongSpline);

				FSplinePosition SplinePos = Spline::GetGameplaySpline(PropLine).GetSplinePositionAtSplineDistance(DistanceAlongSpline);
				Swing.SetWorldLocation(SplinePos.GetWorldLocation() + FVector(0, 0, HeightOffset));

				if (bUpdateRotation)
					UpdateRotation(SplinePos);
			}
		}

		else
		{
			Speed += Acceleration*DeltaSeconds;
			Speed = Math::Clamp(Speed, MinSpeed, MaxSpeed);

			DistanceAlongSpline += Speed * DeltaSeconds;
			DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0, MaxDistanceAlongSpline);

			FSplinePosition SplinePos = Spline::GetGameplaySpline(PropLine).GetSplinePositionAtSplineDistance(DistanceAlongSpline);
			Swing.SetWorldLocation(SplinePos.GetWorldLocation() + FVector(0, 0, HeightOffset));

			if (bUpdateRotation)
				UpdateRotation(SplinePos);
		}
	}

	void UpdateRotation(FSplinePosition SplinePos)
	{
		FRotator Rot = SplinePos.WorldRotation.Rotator();
		Rot.Roll = 0.0;
		Rot.Pitch = 0.0;
		SetActorRotation(Rot);
	}
}