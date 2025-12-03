class USolarFlareSplineMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	USolarFlareSplineMoveComponent SplineMoveComp;

	bool bReachedEnd;
	bool bRunningPause;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineMoveComp = USolarFlareSplineMoveComponent::Get(Owner);
		bRunningPause = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.ActorLocation = SplineMoveComp.SplinePos.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineMoveComp.TargetSpeed = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SplineMoveComp.bIsActive)
		{
			if (Time::GameTimeSeconds > SplineMoveComp.PauseTime)
			{
				SplineMoveComp.TargetSpeed = SplineMoveComp.Speed;

				if (bRunningPause)
				{
					bRunningPause = false;
					SplineMoveComp.OnSolarFlareSplineMoveCompStartMoving.Broadcast();
				}
			}
		}
		else
		{
			SplineMoveComp.TargetSpeed = 0.0;
		}

		SplineMoveComp.CurrentSpeed = Math::FInterpConstantTo(SplineMoveComp.CurrentSpeed, SplineMoveComp.TargetSpeed, DeltaTime, SplineMoveComp.InterpSpeed);

		if (SplineMoveComp.bBackAndForth && !SplineMoveComp.SplineComp.IsClosedLoop() && !bRunningPause)
		{
			if (SplineMoveComp.SplinePos.CurrentSplineDistance >= SplineMoveComp.SplineComp.SplineLength && SplineMoveComp.Direction > 0)
			{
				SplineMoveComp.DirectionTarget = -1;
				SplineMoveComp.RunPause();
				bRunningPause = true;
				bReachedEnd = true;
				SplineMoveComp.TargetSpeed = 0.0;
				SplineMoveComp.OnSolarFlareSplineMoveCompStopMoving.Broadcast();
				SplineMoveComp.OnSolarFlareSplineMoveCompReachedEnd.Broadcast();

				// if (SplineMoveComp.bDebugPrint)
				// 	Print("CHANGED DIR: " + SplineMoveComp.Direction);
			}
			else if (SplineMoveComp.SplinePos.CurrentSplineDistance == 0.0 && SplineMoveComp.Direction < 0)
			{
				SplineMoveComp.DirectionTarget = 1;
				SplineMoveComp.RunPause();
				bRunningPause = true;
				SplineMoveComp.TargetSpeed = 0.0;
				SplineMoveComp.OnSolarFlareSplineMoveCompReachedStart.Broadcast();
				SplineMoveComp.OnSolarFlareSplineMoveCompStopMoving.Broadcast();

				// if (SplineMoveComp.bDebugPrint)
				// 	Print("CHANGED DIR: " + SplineMoveComp.Direction);
			}
		}
		else if (!SplineMoveComp.bBackAndForth && SplineMoveComp.SplinePos.CurrentSplineDistance == SplineMoveComp.SplineComp.SplineLength && !SplineMoveComp.SplineComp.IsClosedLoop() && !bReachedEnd)
		{
			bReachedEnd = true;
			SplineMoveComp.OnSolarFlareSplineMoveCompReachedEnd.Broadcast();
			SplineMoveComp.OnSolarFlareSplineMoveCompStopMoving.Broadcast();
		}
		
		if (SplineMoveComp.SplinePos.CurrentSplineDistance < SplineMoveComp.SplineComp.SplineLength && !SplineMoveComp.SplineComp.IsClosedLoop() && bReachedEnd)
		{
			bReachedEnd = false;
		}

		// ChangeDirectionsMultiplier = Math::FInterpConstantTo(ChangeDirectionsMultiplier, 1.0, DeltaTime, ChangeDirectionsIncreasePerSecond);
		SplineMoveComp.Direction = Math::FInterpConstantTo(SplineMoveComp.Direction, SplineMoveComp.DirectionTarget, DeltaTime, SplineMoveComp.DirectionInterpSpeed);
	
		// if (SplineMoveComp.bDebugPrint)
		// 	PrintToScreen(f"{ChangeDirectionsMultiplier=}");

		SplineMoveComp.SplinePos.Move(SplineMoveComp.CurrentSpeed * SplineMoveComp.Direction * DeltaTime);

		Owner.ActorLocation = SplineMoveComp.SplinePos.WorldLocation;

		if (SplineMoveComp.bFollowRotation)
			Owner.ActorRotation = SplineMoveComp.SplinePos.WorldRotation.Rotator();
	}
};