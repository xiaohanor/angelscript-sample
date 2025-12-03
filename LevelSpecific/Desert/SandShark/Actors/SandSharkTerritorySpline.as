class ASandSharkTerritorySpline : ASplineActor
{
	UPROPERTY(DefaultComponent, NotEditable)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionProfileName(n"TriggerPlayerOnly");
	default SphereComp.bVisible = false;
	default SphereComp.bHiddenInGame = true;

	default Spline.EditingSettings.SplineColor = FLinearColor::LucBlue;

	TPerPlayer<bool> RelevantPlayers;

	UPROPERTY(EditAnywhere)
	TArray<ASandSharkChaseIgnoreZone> PlayerIgnoreZones;

	TPerPlayer<int> PlayerIgnoreTriggerOverlapCount;

	FHazeRuntimeSpline RuntimeSpline;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(SphereComp.WorldLocation, SphereComp.SphereRadius, 12, FLinearColor::Yellow, 8);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SphereComp.WorldLocation = Spline.BoundsOrigin;
		SphereComp.SphereRadius = Spline.GetBoundsRadius();
		for (int i = 0; i < Spline.SplinePoints.Num(); i++)
		{
			Spline.SplinePoints[i].RelativeRotation = FQuat::Identity;
		}

		auto SplinePointTransform = Spline.GetWorldTransformAtSplineDistance(0);
		FVector DirToCenter = (SphereComp.WorldLocation - SplinePointTransform.Location).GetSafeNormal2D();
		float Dot = DirToCenter.DotProduct(SplinePointTransform.Rotation.RightVector);
		if (Dot < 0)
		{
			ReverseSplinePointsOrder();
		}

		Spline.UpdateSpline();
	}

	void ReverseSplinePointsOrder()
	{
		TArray<FHazeSplinePoint> ReversedSplinePoints;
		ReversedSplinePoints.Reserve(Spline.SplinePoints.Num());

		for (int i = Spline.SplinePoints.Num() - 1; i >= 0; i--)
		{
			// Create a new array with the points in the reverse order
			ReversedSplinePoints.Add(Spline.SplinePoints[i]);

			int LastIndex = ReversedSplinePoints.Num() - 1;

			if (Spline.SplinePoints[i].bOverrideTangent)
			{
				ReversedSplinePoints[LastIndex].ArriveTangent = -Spline.SplinePoints[i].LeaveTangent;
				ReversedSplinePoints[LastIndex].LeaveTangent = -Spline.SplinePoints[i].ArriveTangent;
			}
		}

		Spline.SplinePoints = ReversedSplinePoints;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereComp.SphereRadius = Spline.GetBoundsRadius();
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		SphereComp.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		for (auto IgnoreTrigger : PlayerIgnoreZones)
		{
			if (IgnoreTrigger == nullptr)
				continue;
			IgnoreTrigger.TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnIgnoreTriggerPlayerEnter");
			IgnoreTrigger.TriggerComp.OnPlayerLeave.AddUFunction(this, n"OnIgnoreTriggerPlayerExit");
		}

		for (auto Player : Game::Players)
			UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnRespawn");
		
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		PlayerIgnoreTriggerOverlapCount[RespawnedPlayer] = 0;
	}

	UFUNCTION()
	private void OnIgnoreTriggerPlayerExit(AHazePlayerCharacter Player)
	{
		int OverlapCount = PlayerIgnoreTriggerOverlapCount[Player] - 1;
		PlayerIgnoreTriggerOverlapCount[Player] = Math::Max(0, OverlapCount);
	}

	UFUNCTION()
	private void OnIgnoreTriggerPlayerEnter(AHazePlayerCharacter Player)
	{
 		PlayerIgnoreTriggerOverlapCount[Player] = PlayerIgnoreTriggerOverlapCount[Player] + 1;
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		RelevantPlayers[Player] = false;
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								 UPrimitiveComponent OtherComp, int OtherBodyIndex,
								 bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		RelevantPlayers[Player] = true;
	}

	bool CheckPlayerInsideSpline(AHazePlayerCharacter Player)
	{
		if (!RelevantPlayers[Player])
			return false;

		auto ClosestSplinePoint = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FVector DirToPlayer = (Player.ActorLocation - ClosestSplinePoint.WorldLocation).GetSafeNormal2D();
		float Dot = DirToPlayer.DotProduct(ClosestSplinePoint.WorldRightVector);

		return Dot >= 0;
	}
};