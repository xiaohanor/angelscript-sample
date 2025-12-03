class UStoneBeastTailSegmentSpeedTrackerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;
	AStoneBeastTailSegment TailSegment;

	FVector PreviousLocation;

	float AverageSpeedCheckInterval = 0.2;

	float TimeWhenCheckedAverage = 0;

	bool bMovingUp = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailSegment = Cast<AStoneBeastTailSegment>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TailSegment.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TailSegment.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousLocation = TailSegment.SegmentTransform.Location;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NewVerticalSpeed = (TailSegment.SegmentTransform.Location.Z - PreviousLocation.Z) / DeltaTime;
		TailSegment.AccSpeed.AccelerateTo(NewVerticalSpeed, 0.5, DeltaTime);

		TailSegment.TrackSpeed(TailSegment.AccSpeed.Value);

		if (Time::GetGameTimeSince(TimeWhenCheckedAverage) > AverageSpeedCheckInterval)
		{
			float AverageSpeed = TailSegment.GetAverageSpeed();
			float Delta = Math::Abs(AverageSpeed - TailSegment.PreviousAverageSpeed);
			
			if (AverageSpeed > TailSegment.PreviousAverageSpeed && !bMovingUp)
			{
				bMovingUp = true;
				TailSegment.bIsMovingUp = true;
				FStoneBeastTailSegmentStartMovingUpParams Params;
				Params.TailSegment = TailSegment;
				UStoneBeastTailSegmentEffectHandler::Trigger_OnTailSegmentStartMovingUp(TailSegment, Params);
				//Print(f"{TailSegment.Name} MOVING UP", 1);
			}
			else if (AverageSpeed < TailSegment.PreviousAverageSpeed && bMovingUp)
			{
				bMovingUp = false;
				TailSegment.bIsMovingUp = false;
				FStoneBeastTailSegmentStartMovingDownParams Params;
				Params.TailSegment = TailSegment;
				UStoneBeastTailSegmentEffectHandler::Trigger_OnTailSegmentStartMovingDown(TailSegment, Params);
				//Print(f"{TailSegment.Name} MOVING DOWN", 1);
			}

			TailSegment.PreviousAverageSpeed = AverageSpeed;
			TimeWhenCheckedAverage = Time::GameTimeSeconds;
		}

		TailSegment.CurrentVerticalSpeed = NewVerticalSpeed;

		float SpeedSize = Math::Abs(TailSegment.CurrentVerticalSpeed);
		float SpeedAlpha = Math::Saturate(SpeedSize / TailSegment.MaxVerticalSpeed);
		FStoneBeastTailSegmentMoveUpdateParams Params;
		Params.TailSegment = TailSegment;
		Params.VerticalSpeed = SpeedSize;
		Params.VerticalSpeedDirection = Math::Sign(TailSegment.CurrentVerticalSpeed);
		Params.MoveSpeedAlpha = SpeedAlpha;
		UStoneBeastTailSegmentEffectHandler::Trigger_OnTailSegmentMoveUpdate(TailSegment, Params);
	}
};