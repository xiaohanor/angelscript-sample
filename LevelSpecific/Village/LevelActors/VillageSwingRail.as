event void FOnSwingRailReachEnd();

class AVillageSwingRail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USwingPointComponent Swing;

	UPROPERTY(EditInstanceOnly)
	AHazeActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	float HeightOffset = -90;

	UPROPERTY(EditInstanceOnly)
	float Acceleration = 400;

	UPROPERTY(EditInstanceOnly)
	float MaxSpeed = 800;

	UPROPERTY(EditInstanceOnly)
	float MinSpeed = 400;

	UPROPERTY(EditInstanceOnly)
	bool bUpdateRotation = true;

	float Speed = 0;
	bool bIsAttached = false;
	TArray<AHazePlayerCharacter> AttachedPlayers;
	float DistanceAlongSpline = 0;
	float MaxDistanceAlongSpline = 0;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FOnSwingRailReachEnd OnReachEnd;
	private bool bHasReachedSplineEnd = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (SplineActor != nullptr)
		{
			UHazeSplineComponent Spline = UHazeSplineComponent::Get(SplineActor);
			if (Spline != nullptr)
			{
				FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(0);
				SetActorLocation(SplinePos.GetWorldLocation() + FVector(0, 0, HeightOffset));

				if (bUpdateRotation)
					UpdateRotation(SplinePos);
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Swing.OnGrappleHookReachedSwingPointEvent.AddUFunction(this, n"HandlePlayerAttachToSwing");
		Swing.OnPlayerDetachedEvent.AddUFunction(this, n"HandlePlayerDetachFromSwing");

		SplineComp = UHazeSplineComponent::Get(SplineActor);
		MaxDistanceAlongSpline = SplineComp.SplineLength;
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
		if (AttachedPlayers.Num() <= 0)
		{
			if (DistanceAlongSpline <= 0)
			{
				SetActorTickEnabled(false);
			}

			else
			{
				Speed -= Acceleration * DeltaSeconds;
				Speed = Math::Clamp(Speed, -MinSpeed, -MaxSpeed);

				DistanceAlongSpline += Speed * DeltaSeconds;
				DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0, MaxDistanceAlongSpline);

				FSplinePosition SplinePos = SplineComp.GetSplinePositionAtSplineDistance(DistanceAlongSpline);
				SetActorLocation(SplinePos.GetWorldLocation() + FVector(0, 0, HeightOffset));

				if (bUpdateRotation)
					UpdateRotation(SplinePos);
				
				bHasReachedSplineEnd = false;
			}
		}
		else
		{
			Speed += Acceleration * DeltaSeconds;
			Speed = Math::Clamp(Speed, MinSpeed, MaxSpeed);

			DistanceAlongSpline += Speed * DeltaSeconds;
			DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0, MaxDistanceAlongSpline);

			FSplinePosition SplinePos = SplineComp.GetSplinePositionAtSplineDistance(DistanceAlongSpline);
			SetActorLocation(SplinePos.GetWorldLocation() + FVector(0, 0, HeightOffset));

			const bool bReachedEnd = Math::IsNearlyEqual(DistanceAlongSpline, MaxDistanceAlongSpline);			
			if(!bHasReachedSplineEnd && bReachedEnd)
				OnReachEnd.Broadcast();

			if (bUpdateRotation)
				UpdateRotation(SplinePos);

			bHasReachedSplineEnd = bReachedEnd;

			if (!bHasReachedSplineEnd)
			{
				for (AHazePlayerCharacter Player : AttachedPlayers)
				{
					float LeftFF = Math::Sin(Time::GetGameTimeSeconds() * 50.0) * 0.3;
					float RightFF = Math::Sin(-Time::GetGameTimeSeconds() * 50.0) * 0.3;
					Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
				}
			}
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