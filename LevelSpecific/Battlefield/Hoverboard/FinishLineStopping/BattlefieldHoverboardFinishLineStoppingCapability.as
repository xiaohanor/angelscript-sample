struct FBattlefieldHoverboardFinishLineActivateParams
{
	float FinishTime;
	float FinishPoints;
}

class UBattlefieldHoverboardFinishLineStoppingCapabilityCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickComponent TrickComp;
	UBattlefieldHoverboardTrickComponent OtherPlayerTrickComp;

	bool bHasStartedAnimation = false;

	FHazeRuntimeSpline StopSpline;
	float StartSpeed;
	const float TargetSpeed = 1850.0;

	float CurrentSplineDistance = 0.0;
	float CurrentSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		OtherPlayerTrickComp = UBattlefieldHoverboardTrickComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardFinishLineActivateParams& Params) const
	{
		if(!HoverboardComp.bHasFinished)
			return false;
		
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(Player.IsMio()
		&& HoverboardComp.MioFinishLineActor == nullptr)
			return false;

		if(Player.IsZoe()
		&& HoverboardComp.ZoeFinishLineActor == nullptr)
			return false;

		Params.FinishTime = Time::PredictedGlobalCrumbTrailTime;
		Params.FinishPoints = TrickComp.CurrentTotalTrickPoints;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardFinishLineActivateParams Params)
	{
		Player.BlockCapabilities(BattlefieldHoverboardCapabilityTags::HoverboardTrick, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		bHasStartedAnimation = false;

		StopSpline = GetStopSpline();

		StartSpeed = Player.ActorVelocity.Size();
		CurrentSpeed = StartSpeed;
		CurrentSplineDistance = 0.0;

		HoverboardComp.FinishTime = Params.FinishTime;
		HoverboardComp.FinishPoints = Params.FinishPoints;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BattlefieldHoverboardCapabilityTags::HoverboardTrick, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto TempLog = TEMPORAL_LOG(Player, "Hoverboard Exit").RuntimeSpline("Exit Spline", StopSpline);

		float PreviousSplineAlpha = CurrentSplineDistance / StopSpline.Length;
		CurrentSpeed = Math::Lerp(StartSpeed, TargetSpeed, PreviousSplineAlpha);
		CurrentSplineDistance += (CurrentSpeed * DeltaTime);	

		float SplineAlpha = CurrentSplineDistance / StopSpline.Length;
		TempLog
			.Value("Spline Alpha", SplineAlpha)
			.Value("Current Speed", CurrentSpeed)
			.Value("Current Spline Distance", CurrentSplineDistance)
			.Value("Spline Length", StopSpline.Length)
			.Value("Actor Velocity", Player.ActorVelocity)
		;
		if(SplineAlpha < 1.0)
		{
			if (MoveComp.PrepareMove(Movement))
			{
				if (HasControl())
				{
					FVector SplineLocation;
					FQuat SplineQuat;

					StopSpline.GetLocationAndQuatAtDistance(CurrentSplineDistance, SplineLocation, SplineQuat);

					Movement.SetRotation(SplineQuat.Rotator());
					
					FVector Delta = (SplineLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector);
					Movement.AddDelta(Delta);

					HoverboardComp.WantedRotation = SplineQuat.Rotator();

					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();

					TempLog
						.Sphere("Spline Location", SplineLocation, 50, FLinearColor::Blue, 10)
						.Rotation("Spline Rotation", SplineQuat, SplineLocation, 500.0)
					;
				}
				// Remote update
				else
				{
					Movement.ApplyCrumbSyncedGroundMovement();
				}

				MoveComp.ApplyMoveAndRequestLocomotion(Movement, BattlefieldHoverboardLocomotionTags::Hoverboard);
			}
		}
		else
		{
			if(!bHasStartedAnimation)
			{
				StartEnterAnim();
			}
		}
	}

	private void StartEnterAnim()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnEnterBlendingOut"), HoverboardComp.ExitAnim_Enter);
		auto FinishLineManager = TListedActors<ABattlefieldFinishLineManager>().Single;
		if(Player.IsMio())
			FinishLineManager.OnMioFinished.Broadcast();
		else
			FinishLineManager.OnZoeFinished.Broadcast();
		bHasStartedAnimation = true;
	}

	UFUNCTION()
	private void OnEnterBlendingOut()
	{
		Player.PlaySlotAnimation(HoverboardComp.ExitAnim_MH);
		TrickComp.bIsWaitingAtExit = true;
		
		auto FinishLineManager = TListedActors<ABattlefieldFinishLineManager>().Single;
		if(OtherPlayerTrickComp == nullptr)
			OtherPlayerTrickComp = UBattlefieldHoverboardTrickComponent::Get(Player.OtherPlayer);
		if(OtherPlayerTrickComp.bIsWaitingAtExit)
		{
			FinishLineManager.OnBothFinished.Broadcast();
		}
	}

	const float SecondPointVelocitySamplingDuration = 0.5;
	const float TargetPointEnterAnglePointDistance = 200.0;
	private FHazeRuntimeSpline GetStopSpline() const
	{
		FHazeRuntimeSpline NewSpline;
		NewSpline.CustomCurvature = 1.0;
		NewSpline.AddPoint(Player.ActorLocation);
		NewSpline.AddPoint(Player.ActorLocation + Player.ActorVelocity * SecondPointVelocitySamplingDuration);

		AActor TargetActor = Player.IsMio() 
			? HoverboardComp.MioFinishLineActor 
			: HoverboardComp.ZoeFinishLineActor;

		NewSpline.AddPoint(TargetActor.ActorLocation - TargetActor.ActorForwardVector * TargetPointEnterAnglePointDistance);
		NewSpline.AddPoint(TargetActor.ActorLocation);

		return NewSpline;
	}
};