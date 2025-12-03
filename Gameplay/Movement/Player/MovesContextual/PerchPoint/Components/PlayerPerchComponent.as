
class UPlayerPerchComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;

	//Points set by overlapping PerchEnterZones
	TArray<UPerchEnterByZoneComponent> QueryZones;

	//Vertical offset when performing GroundedEnter Jump
	UPROPERTY()
	UCurveFloat HeightCurve;
	UPROPERTY()
	UHazeCameraSettingsDataAsset PerchPointEnterCamSetting;
	UPROPERTY()
	UHazeCameraSettingsDataAsset PerchPointJumpOffCamSetting;
	UPROPERTY()
	UHazeCameraSettingsDataAsset PerchingCamSetting;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PerchJumpOffCamShake;

	UPROPERTY()
	UHazeCameraSettingsDataAsset PerchSplineDashCameraSetting;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PerchSplineDashShake;
	UPROPERTY()
	UForceFeedbackEffect PerchSplineDashFF;

	private TArray<FInstigator> PerchIdleBlockers;

	int ChainedJumps = 0;

	float TimeSinceLastJump = 0.0;
	float PerchCooldown = 0.0;
	float LastJumpOffTime = 0.0;
	float LastPerchStartTime = 0.0;

	bool bIsLandingOnSpline = false;
	FVector SplineLandStartOffset;
	FVector SplineLandStartVelocity;
	bool bSplineLandWasAirbone = false;

	FSplinePosition PerchSplinePosition;
	bool bIsGroundedOnPerchSpline = false;

	UPlayerPerchSettings Settings;
	FPerchData Data;
	FPerchAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UPlayerPerchSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PerchCooldown > 0)
			PerchCooldown -= DeltaSeconds;

		TimeSinceLastJump += DeltaSeconds;
		if(TimeSinceLastJump > 1.0 && ChainedJumps > 1)
			ChainedJumps = 0;

		// Update data for all query zones we are currently tracking
		for (auto QueryZone : QueryZones)
		{
			FVector PrevLocation = QueryZone.PreviousPerchWorldLocation;
			QueryZone.PreviousPerchWorldLocation = QueryZone.OwningPerchPoint.GetLocationForVelocity();
			QueryZone.PreviousPerchWorldVelocity = (QueryZone.PreviousPerchWorldLocation - PrevLocation) / DeltaSeconds;
		}
	}

	//Check if we are within the chain jump window and reset the timer
	void ResetJumpTimer()
	{
		if(TimeSinceLastJump < 1.0)
			ChainedJumps++;

		TimeSinceLastJump = 0.0;
	}

	//Calculate Distance and AngleDifference to point and set in PerchComp.Data
	void CalculateDistAndAngleDiffs()
	{
		if(Data.ActivePerchPoint == nullptr)
			return;

		FVector Direction = Data.ActivePerchPoint.WorldLocation - Player.ActorLocation;
		Data.DistToTarget = Direction.Size();

		FVector HorizontalDelta = Direction.ConstrainToPlane(MoveComp.WorldUp);
		Data.AngleDiff = Math::Atan2(HorizontalDelta.DotProduct(Player.ActorRightVector), HorizontalDelta.DotProduct(Player.ActorForwardVector));
		Data.AngleDiff = Math::RadiansToDegrees(Data.AngleDiff);
	}

	void StartPerching(UPerchPointComponent Point, bool TeleportToPoint = false)
	{
		if(Data.bPerching || Point == nullptr)
			return;

		Data.bPerching = true;
		Data.ActivePerchPoint = Point;
		Data.ActivePerchPoint.bMovePoint = false;
		Data.ActivePerchPoint.IsPlayerOnPerchPoint[Player] = true;
		LastPerchStartTime = Time::GameTimeSeconds;

		if(Point.bHasConnectedSpline)
		{
			Data.ActiveSpline = Point.ConnectedSpline;
			Data.bInPerchSpline = true;
		}

		if (TeleportToPoint)	
		{
			Player.SetActorLocation(Data.ActivePerchPoint.WorldLocation);
			MoveComp.FollowComponentMovement(Data.ActivePerchPoint, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Interaction);
		}

		if(PerchingCamSetting != nullptr)
			Player.ApplyCameraSettings(PerchingCamSetting, 2, this, EHazeCameraPriority::Low); 
	}

	void StartPerchingOnSplineFraction(UPerchPointComponent Point, float SplineFraction)
	{			
		if(Data.bPerching || Point == nullptr || !Point.bHasConnectedSpline)
			return;

		Data.bPerching = true;
		Data.ActivePerchPoint = Point;
		Data.ActivePerchPoint.bMovePoint = false;
		Data.ActivePerchPoint.IsPlayerOnPerchPoint[Player] = true;
		LastPerchStartTime = Time::GameTimeSeconds;

		Data.ActiveSpline = Point.ConnectedSpline;
		Data.bInPerchSpline = true;

		if(Player.IsMio())
			Data.ActiveSpline.PerchSplineMio.SnapToWorldLocation(Data.ActiveSpline.Spline.GetWorldLocationAtSplineFraction(SplineFraction));
		else
			Data.ActiveSpline.PerchSplineZoe.SnapToWorldLocation(Data.ActiveSpline.Spline.GetWorldLocationAtSplineFraction(SplineFraction));

		Player.SetActorLocation(Data.ActiveSpline.Spline.GetWorldLocationAtSplineFraction(SplineFraction));
		MoveComp.FollowComponentMovement(Data.ActivePerchPoint, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Interaction);

		if(PerchingCamSetting != nullptr)
			Player.ApplyCameraSettings(PerchingCamSetting, 2, this, EHazeCameraPriority::Low); 
	}

	void StopPerching(bool bApplyPerchCooldown = true)
	{
		if(!Data.bPerching)
			return;

		MoveComp.UnFollowComponentMovement(this);
		Player.ClearSettingsByInstigator(Data.ActivePerchPoint);
		Player.ClearCameraSettingsByInstigator(this);

		if (IsValid(Data.ActivePerchPoint))
		{
			Data.ActivePerchPoint.bMovePoint = true;
			Data.ActivePerchPoint.IsPlayerOnPerchPoint[Player] = false;
		}
		Data.ResetData();

		if (bApplyPerchCooldown)
			PerchCooldown = 0.3;
	}

	bool StartedJumpOffWithinDuration(float Duration)
	{
		if (Data.bJumpingOff)
			return Time::GetGameTimeSince(LastJumpOffTime) <= Duration;
		return false;
	}

	bool IsCurrentlyPerching()
	{
		return (Data.State == EPlayerPerchState::PerchingOnPoint || Data.State == EPlayerPerchState::PerchingOnSpline) && Data.bPerching;
	}

	EPlayerPerchState GetState() const property
	{
		return Data.State;
	}

	void SetState(EPlayerPerchState NewState) property
	{
		Data.State = NewState;
		AnimData.State = NewState;
	}	

	void AddPerchIdleBlocker(FInstigator Instigator)
	{
		PerchIdleBlockers.Add(Instigator);
	}

	void RemovePerchIdleBlocker(FInstigator Instigator)
	{
		PerchIdleBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsPerchIdleBlocked() const
	{
		return PerchIdleBlockers.Num() > 0;
	}

	bool VerifyReachedPerchSplineEnd(bool bIsForJump = false) const
	{
		bool bIsInAir = Data.bSplineJump || !MoveComp.HasCustomMovementStatus(n"Perching");
		if (!bIsInAir)
		{
			if (!Data.ActiveSpline.StartZoneSettings.bAllowRunningOffEdge
				&& !Data.ActiveSpline.EndZoneSettings.bAllowRunningOffEdge)
			{
				return false;
			}
		}

		FVector InputDirection = MoveComp.GetNonLockedMovementInput().GetSafeNormal();
		FVector VelocityDirection = MoveComp.HorizontalVelocity.GetSafeNormal();

#if !RELEASE
		FString LogPrefix = bIsForJump ? "Jump:" : "";
		auto Log = TEMPORAL_LOG(this);
		Log.Value(LogPrefix+"bIsInAir", bIsInAir);
#endif

		float RunOffRequiredAngle = PI * 0.5;
		if (Data.bSplineJump)
			RunOffRequiredAngle = PI * 0.25;
		else if (Time::GetGameTimeSince(LastPerchStartTime) < 1.0)
			RunOffRequiredAngle = PI * 0.6;

#if !RELEASE
		Log.Value(LogPrefix+"RunOffRequiredAngle", RunOffRequiredAngle);
#endif

		if ((Data.ActiveSpline.StartZoneSettings.bAllowRunningOffEdge || bIsInAir)
			 && Data.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(0.0).Dist2D(Player.ActorLocation, MoveComp.WorldUp) < 50.0)
		{
			FVector SplineVector = Data.ActiveSpline.Spline.GetWorldForwardVectorAtSplineDistance(0.0); 
			SplineVector = SplineVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

#if !RELEASE
			Log.Value(LogPrefix+"StartSplineVector", SplineVector);
			Log.Value(LogPrefix+"InputDirection", InputDirection);
			Log.Value(LogPrefix+"InputAngularDistance", InputDirection.AngularDistance(SplineVector));
			Log.Value(LogPrefix+"VelocityDirection", VelocityDirection);
			Log.Value(LogPrefix+"VelocityAngularDistance", VelocityDirection.AngularDistance(SplineVector));
#endif

			if (!SplineVector.IsNearlyZero())
			{
				if (InputDirection.Size() > 0 && InputDirection.AngularDistance(SplineVector) > RunOffRequiredAngle)
					return true;
				if (bIsInAir && VelocityDirection.Size() > 0 && VelocityDirection.AngularDistance(SplineVector) > RunOffRequiredAngle)
					return true;
			}
		}
		else if ( (Data.ActiveSpline.EndZoneSettings.bAllowRunningOffEdge || bIsInAir)
				&& Data.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(
					Data.ActiveSpline.Spline.SplineLength).Dist2D(Player.ActorLocation, MoveComp.WorldUp) < 50.0)
		{
			FVector SplineVector = -Data.ActiveSpline.Spline.GetWorldForwardVectorAtSplineDistance(Data.ActiveSpline.Spline.SplineLength); 
			SplineVector = SplineVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

#if !RELEASE
			Log.Value(LogPrefix+"EndSplineVector", SplineVector);
			Log.Value(LogPrefix+"InputDirection", InputDirection);
			Log.Value(LogPrefix+"InputAngularDistance", InputDirection.AngularDistance(SplineVector));
			Log.Value(LogPrefix+"VelocityDirection", VelocityDirection);
			Log.Value(LogPrefix+"VelocityAngularDistance", VelocityDirection.AngularDistance(SplineVector));
#endif

			if (!SplineVector.IsNearlyZero())
			{
				if (InputDirection.Size() > 0 && InputDirection.AngularDistance(SplineVector) > RunOffRequiredAngle)
					return true;
				if (bIsInAir && VelocityDirection.Size() > 0 && VelocityDirection.AngularDistance(SplineVector) > RunOffRequiredAngle)
					return true;
			}
		}

		if (Data.bSplineJump && Data.ActiveSpline.bAllowSidewaysJumpOff)
		{
			float SplineDistance = Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation); 
			FVector SplineVector = Data.ActiveSpline.Spline.GetWorldForwardVectorAtSplineDistance(SplineDistance); 
			SplineVector = SplineVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			
#if !RELEASE
			Log.Value(LogPrefix+"MiddleSplineVector", SplineVector);
			Log.Value(LogPrefix+"InputDirection", InputDirection);
			Log.Value(LogPrefix+"InputAngularDistance", InputDirection.AngularDistance(SplineVector));
#endif

			if (!SplineVector.IsNearlyZero())
			{
				float InputAngle = InputDirection.AngularDistance(SplineVector);
				if (InputDirection.Size() > 0 && InputAngle > PI * 0.25 && InputAngle < PI * 0.75)
					return true;
			}
		}

		return false;
	}	
}

struct FPerchData
{
	//Current Targeted point (Not yet active), is assigned by any move transitioning into perch
	UPROPERTY()
	UPerchPointComponent TargetedPerchPoint;

	//Current Active Point, is set as active when StartPerching is called.
	UPROPERTY()
	UPerchPointComponent ActivePerchPoint;

	//Currently Targeted Spline (Not yet active), is assigned by PerchSplineEndTriggerZones when transitioning into PerchSplineMovement
	UPROPERTY()
	APerchSpline TargetedSpline;
	UPROPERTY()
	APerchSpline ActiveSpline;
	UPROPERTY()
	EPlayerPerchState State;

	UPROPERTY()
	float AngleDiff;
	UPROPERTY()
	float DistToTarget;
	UPROPERTY()
	float EnterTime;
	UPROPERTY()
	float CurrentSplineDistance;

	//Rotation Rate when perching on point
	UPROPERTY()
	float RotRate;
	UPROPERTY()
	FVector PerchLandingVerticalVelocity;
	UPROPERTY()
	FVector PerchLandingHorizontalVelocity;

	//Are we currently perching on a point
	UPROPERTY()
	bool bPerching;
	UPROPERTY()
	bool bInPerchSpline;
	UPROPERTY()
	bool bJumpingOff;
	UPROPERTY()
	bool bSplineJump;

	//Are we inside the the correct ranges + minimum input size
	UPROPERTY()
	bool bHasValidInput;

	/* SideScroller Mode Data */
	bool bPerformingPerchTurnaround = false;

	void ResetData()
	{
		AngleDiff = 0.0;
		DistToTarget = 0.0;
		RotRate = 0.0;
		CurrentSplineDistance = 0;

		EnterTime = 0.0;

		PerchLandingVerticalVelocity = FVector::ZeroVector;
		PerchLandingHorizontalVelocity = FVector::ZeroVector;

		bPerformingPerchTurnaround = false;

		bPerching = false;
		bInPerchSpline = false;
		bHasValidInput = false;

		ActivePerchPoint = nullptr;
		ActiveSpline = nullptr;
		State = EPlayerPerchState::Inactive;
	}
}

struct FPerchAnimData
{
	//Are we currently in a transition move to perch
	UPROPERTY()
	bool bInEnter;
	UPROPERTY()
	bool bPerformingTurnaroundRight;
	UPROPERTY()
	bool bPerformingTurnaroundLeft;
	UPROPERTY()
	bool bLanding;
	UPROPERTY()
	bool bInGroundedEnter;
	UPROPERTY()
	bool bDashing;
	UPROPERTY()
	bool bReachedEndOfSpline = false;
	//How much we should lean based on spline curvature
	UPROPERTY()
	float AdditiveLean;
	//Lean alpha based on velocity
	UPROPERTY()
	float LeanAlpha;
	UPROPERTY()
	float VerticalSlopeAngle;


	EPlayerPerchState State;

	void ResetAnimData()
	{
		bInEnter = false;
		bLanding = false;
		bInGroundedEnter = false;
		bPerformingTurnaroundRight = false;
		bPerformingTurnaroundLeft = false;
		bDashing = false;
		bReachedEndOfSpline = false;

		AdditiveLean = 0;
		LeanAlpha = 0;
		VerticalSlopeAngle = 0;

		State = EPlayerPerchState::Inactive;
	}
}

enum EPlayerPerchState
{	
	//No perch Capability active or set to active
	Inactive,
	JumpTo,
	TransitionBetweenPoints,
	QuickGrapple,
	Grapple,
	//Perch is active or next to be activated
	PerchingOnPoint,
	//PerchOnSpline is active or next to be activated
	PerchingOnSpline,
	GroundedSplineEnter
}