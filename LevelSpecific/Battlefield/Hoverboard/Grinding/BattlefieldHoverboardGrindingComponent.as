asset BattlefieldHoverboardDefaultGrindCameraSettings of UBattlefieldHoverboardCameraControlSettings
{
	RotationDuration = 1.5;
	SettingsBlendTime = 0.25;
}

event void FBattlefieldHoverboardGrindEvent(UBattlefieldHoverboardGrindSplineComponent GrindComp, AHazePlayerCharacter Player);
class UBattlefieldHoverboardGrindingComponent : UActorComponent
{
	UPROPERTY(Category = "Events")
	FBattlefieldHoverboardGrindEvent OnStartedGrinding;

	UPROPERTY(Category = "Events")
	FBattlefieldHoverboardGrindEvent OnStoppedGrinding;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	TArray<UBattlefieldHoverboardGrindSplineComponent> GrindSplineComps;
	UBattlefieldHoverboardGrindSplineComponent CurrentGrindSplineComp;

	AHazePlayerCharacter Player;
	UBattlefieldHoverboardGrindingSettings GrindSettings;

	FSplinePosition CurrentSplinePos;
	TArray<FInstigator> GrindingInstigators;

	TArray<AGrapplePoint> PooledGrapplePoints;

	TOptional<FBattlefieldHoverboardGrindingActivationParams> RespawnActivationParams;

	float MaxGrapplePointVisibleRange;

	bool bIsRubberbanding = false;
	// Only active when on grind (not jumping)
	bool bIsOnGrind = false;
	bool bIsJumpingWhileGrinding = false;
	bool bIsJumpingToGrind = false;
	bool bIsJumpingBetweenGrinds = false;
	FHazeAcceleratedFloat AccGrindRubberbandingSpeed;
	const float RubberbandingDecelerationDuration = 5.0;

	float TimeLastLeftGrindWithJump = -MAX_flt;

	float GrindBalance = 0.0;
	float GrindBalanceVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsRubberbanding
		&& !Math::IsNearlyZero(AccGrindRubberbandingSpeed.Value))
		{
			AccGrindRubberbandingSpeed.AccelerateTo(0, RubberbandingDecelerationDuration, DeltaSeconds);
		}
	}

	UBattlefieldHoverboardGrindSplineComponent GetFirstValidStartGrindSpline(bool bIsOnGround) const
	{
		for(auto GrindSplineComp : GrindSplineComps)
		{
			FSplinePosition ClosestSplinePos = GrindSplineComp.SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);

			TEMPORAL_LOG(Player, "Grind Validation").Page(f"{GrindSplineComp}")
				// .Sphere("Closest Spline Pos", ClosestSplinePos.WorldLocation, 50, ClosestSplinePos.CurrentSplineDistance > GrindSplineComp.DistanceBeforeWhichCanBeGrounded ? FLinearColor::Red : FLinearColor::Green)
				.Value("Current Spline distance", ClosestSplinePos.CurrentSplineDistance)
			;

			// if(bIsOnGround
			// && ClosestSplinePos.CurrentSplineDistance > GrindSplineComp.DistanceBeforeWhichCanBeGrounded)
			// 	continue;

			float DistanceToSplineLocSqrd = ClosestSplinePos.WorldLocation.DistSquared(Player.ActorLocation);
			if(DistanceToSplineLocSqrd < Math::Square(GrindSplineComp.SplineSize))
				return GrindSplineComp;
		}
		return nullptr;
	}

	TOptional<FSplinePosition> GetClosestGrindSplinePositionToWorldLocation(FVector WorldLocation, float MaxDistance, bool bExcludeGrindCurrentlyOn = false) const
	{
		TOptional<FSplinePosition> ClosestSplinePos;
		
		TArray<UBattlefieldHoverboardGrindSplineComponent> GrindSplineCompsToCheck = GrindSplineComps;
		if(bExcludeGrindCurrentlyOn 
		&& CurrentGrindSplineComp != nullptr)
			GrindSplineCompsToCheck.RemoveSingleSwap(CurrentGrindSplineComp);

		float ClosestDistToSplineSqrd = BIG_NUMBER;
		for(auto GrindSplineComp : GrindSplineCompsToCheck)
		{
			FSplinePosition SplinePos = GrindSplineComp.SplineComp.GetClosestSplinePositionToWorldLocation(WorldLocation);
			
			// Too far away, disregard
			float DistanceToSplinePosSqrd = SplinePos.WorldLocation.DistSquared(WorldLocation);
			if(DistanceToSplinePosSqrd > Math::Square(MaxDistance))
				continue;
			
			// Closer than previously closest
			if(DistanceToSplinePosSqrd < ClosestDistToSplineSqrd)
			{
				ClosestSplinePos.Set(SplinePos);
				ClosestDistToSplineSqrd = DistanceToSplinePosSqrd;
			}
		}
		return ClosestSplinePos;
	}

	bool IsGrinding() const
	{
		return GrindingInstigators.Num() > 0;
	}

	FRotator GetCameraLookAheadRotation(FSplinePosition SplinePos, float SpeedForward, bool bDisregardPitch = true) const
	{
		float CurrentGrindPosDistance = SplinePos.CurrentSplineDistance;
		float DistanceToCameraPosition = SpeedForward * GrindSettings.TimeToCameraLookAheadPoint;
		if(!SplinePos.IsForwardOnSpline())
			DistanceToCameraPosition *= -1;

		float CameraLookAheadPositionDistance = CurrentGrindPosDistance + DistanceToCameraPosition;
		
		FSplinePosition CameraLookAheadPosition = SplinePos.CurrentSpline.GetSplinePositionAtSplineDistance(CameraLookAheadPositionDistance);

		FRotator LookAheadRotation = CameraLookAheadPosition.WorldRotation.Rotator();
		if(!SplinePos.IsForwardOnSpline())
			LookAheadRotation.Yaw += 180;

		if(bDisregardPitch)
			LookAheadRotation.Pitch = 0.0;
		LookAheadRotation.Roll = 0.0;

		TEMPORAL_LOG(this)
			.Value("Current Grind Position Distance", CurrentGrindPosDistance)
			.Value("Camera Look Ahead Position Distance", CameraLookAheadPositionDistance)
			.Sphere("Camera Look Ahead Position", CameraLookAheadPosition.WorldLocation, 50, FLinearColor::LucBlue, 5)
		;

		return LookAheadRotation;
	}

	void AddGrindIfDontHave(UBattlefieldHoverboardGrindSplineComponent GrindSplineComp)
	{
		if(GrindSplineComps.Contains(GrindSplineComp))
			return;

		GrindSplineComps.Add(GrindSplineComp);
	}

	void RemoveGrindIfHave(UBattlefieldHoverboardGrindSplineComponent GrindSplineComp)
	{
		if(!GrindSplineComps.Contains(GrindSplineComp))
			return;

		GrindSplineComps.RemoveSingleSwap(GrindSplineComp);
	}
};