struct FRemoteHackingLaunchCapabilityActivationParams
{
	URemoteHackingResponseComponent RemoteHackingResponseComponent;
}

class URemoteHackingLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(n"RemoteHackingLaunch");	

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 5;
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	URemoteHackingPlayerComponent RemoteHackingComp;
	UPlayerTargetablesComponent TargetablesComp;
	UGentlemanComponent GentlemanComp;

	URemoteHackingResponseComponent CurrentResponseComp;

	FVector TargetLocation;
	FVector StartLocation;
	FVector TargetRelativeStartPoint;

	FHazeRuntimeSpline Spline;
	float DistAlongSpline;
	float Speed;
	float EnterSpeed = 2500.0;
	FVector EndPointLocLastframe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		RemoteHackingComp = URemoteHackingPlayerComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (RemoteHackingComp.bHackActive)
			return;

		if (RemoteHackingComp.TargetableWidget.IsValid())
		{
			FTargetableWidgetSettings TargetableWidgetSettings;
			TargetableWidgetSettings.TargetableClass = URemoteHackingResponseComponent;
			TargetableWidgetSettings.DefaultWidget = RemoteHackingComp.TargetableWidget;
			TargetableWidgetSettings.MaximumVisibleWidgets = 1;
			TargetablesComp.ShowWidgetsForTargetables(TargetableWidgetSettings);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRemoteHackingLaunchCapabilityActivationParams& ActivationParams) const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		URemoteHackingResponseComponent TargetedHackingComp = Cast<URemoteHackingResponseComponent>(TargetablesComp.GetPrimaryTargetForCategory(n"RemoteHacking"));
		if (TargetedHackingComp == nullptr)
			return false;

		ActivationParams.RemoteHackingResponseComponent = TargetedHackingComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (DistAlongSpline >= Spline.Length)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FRemoteHackingLaunchCapabilityActivationParams ActivationParams)
	{
		CurrentResponseComp = ActivationParams.RemoteHackingResponseComponent;
		RemoteHackingComp.CurrentHackingResponseComp = CurrentResponseComp;

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"PlayerShadow", this);
		Player.BlockCapabilities(n"Death", this);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		HandleCameraOnActivation();

		//Reset variables before going into the move
		DistAlongSpline = 0.0;
		Speed = EnterSpeed;
		EndPointLocLastframe = RemoteHackingComp.CurrentHackingResponseComp.WorldLocation;
		TargetLocation = RemoteHackingComp.CurrentHackingResponseComp.WorldLocation;
		StartLocation = Player.ActorLocation;
		TargetRelativeStartPoint = RemoteHackingComp.CurrentHackingResponseComp.WorldTransform.InverseTransformPosition(StartLocation);

		// AIs should not try to attack player when launching to remote hack target 
		// (once there it is up to remote hackable capabilty to decide)
		GentlemanComp.SetInvalidTarget(this);

		SpeedEffect::RequestSpeedEffect(Player, 0.1, this, EInstigatePriority::High);

		Player.PlayForceFeedback(RemoteHackingComp.LaunchForceFeedback, false, true, this, 0.6);

		// Should probably get these locations within a function since the exact same thing is done in Tick
		FVector RelativeStartLocation = CurrentResponseComp.WorldTransform.TransformPosition(TargetRelativeStartPoint);
		FVector MiddlePointLoc = CurrentResponseComp.WorldLocation - RelativeStartLocation;
		const float DistToTarget = MiddlePointLoc.Size();

		FRemoteHackingLaunchEventParams LaunchParams;
		LaunchParams.LaunchDuration = DistToTarget / Speed;
		LaunchParams.LaunchSpeed = Speed;
		CurrentResponseComp.OnLaunchStarted.Broadcast(LaunchParams);

		FRemoteHackingStartParams HackingParams;
		HackingParams.TimeToTarget = LaunchParams.LaunchDuration;
		HackingParams.TargetLocation = CurrentResponseComp.WorldLocation;
		URemoteHackingEventHandler::Trigger_OnLaunchStarted(Player, HackingParams);

		CurrentResponseComp.LaunchStarted();

		// Play slot animation
		// Looked kinda bad and was never official, and not having it actually looks kinda good
		/*FHazePlaySlotAnimationParams Params;
		Params.Animation = RemoteHackingComp.Animations.Launch;
		Params.bPauseAtEnd = true;
		Player.PlaySlotAnimation(Params);*/
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);
		Player.UnblockCapabilities(n"Death", this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		Player.ClearCameraSettingsByInstigator(this, 1.0);

		RemoteHackingComp.StartHacking(CurrentResponseComp);
		CurrentResponseComp.HackStarted(false);

		GentlemanComp.ClearInvalidTarget(this);

		// Player.StopSlotAnimationByAsset(RemoteHackingComp.Animations.Launch);

		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.PlayForceFeedback(RemoteHackingComp.StartHackingForceFeedback, false, true, this, 0.6);

		URemoteHackingEventHandler::Trigger_OnLaunchComplete(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float SpeedMultiplier = 1.0 + (ActiveDuration / 0.6);
		float AccelerationMultiplier = Math::Pow(Math::Saturate(ActiveDuration / 0.25), 3);

		FVector RelativeStartLocation = CurrentResponseComp.WorldTransform.TransformPosition(TargetRelativeStartPoint);

		//New cool spline stuff
		FVector MiddlePointLoc = CurrentResponseComp.WorldLocation - RelativeStartLocation;
		float DistToTarget = MiddlePointLoc.Size();
		float EnterSpeedModifier = Math::GetMappedRangeValueClamped(FVector2D(750.0, 2000.0), FVector2D(0.5, 1.0), DistToTarget);
		float Dist = MiddlePointLoc.Size() * 0.4;
		MiddlePointLoc = MiddlePointLoc.GetSafeNormal() * Dist;
		MiddlePointLoc += RelativeStartLocation;
		MiddlePointLoc += Player.MovementWorldUp * 120.0;
		FVector EndPointTangent = CurrentResponseComp.WorldLocation.ConstrainToPlane(FVector::UpVector) - Player.ActorLocation.ConstrainToPlane(FVector::UpVector);
		RelativeStartLocation += CurrentResponseComp.WorldLocation - EndPointLocLastframe;

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(RelativeStartLocation);
		Spline.AddPoint(MiddlePointLoc);
		Spline.AddPoint(CurrentResponseComp.WorldLocation);

		Spline.SetCustomExitTangentPoint(CurrentResponseComp.WorldLocation + EndPointTangent.GetSafeNormal() * 500.0);
		Spline.SetCustomCurvature(0.15);
		Spline.Tension = 0.0;

		EndPointLocLastframe = CurrentResponseComp.WorldLocation;

		FRemoteHackingLaunchTickParams TickParams;
		TickParams.TargetLocation = CurrentResponseComp.WorldLocation;
		URemoteHackingEventHandler::Trigger_OnLaunchTick(Player, TickParams);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.BlockStepDownForThisFrame();

				DistAlongSpline += Speed * SpeedMultiplier * AccelerationMultiplier * DeltaTime;
				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);

				FVector NextLocation = Spline.GetLocationAtDistance(DistAlongSpline);
				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NextLocation, FVector::ZeroVector);

				FVector MoveDelta = NextLocation - Player.ActorLocation;
				if (!MoveDelta.IsNearlyZero())
					Movement.InterpRotationTo(MoveDelta.ToOrientationQuat(), 15, false);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}


			MoveComp.ApplyMove(Movement);
		}

		Player.SetFrameForceFeedback(0.1, 0.1, 0.1, 0.1);
	}

	void HandleCameraOnActivation()
	{
		Player.PlayCameraShake(RemoteHackingComp.LaunchCamShake, this, 2.0);

		auto Poi = Player.CreatePointOfInterest();
		Poi.FocusTarget.SetFocusToComponent(CurrentResponseComp);
		Poi.Settings.Duration = 0.25;

		if (Player.IsMovementCameraBehaviorEnabled())
		{
			FHazeCameraImpulse CamImpulse;
			CamImpulse.CameraSpaceImpulse = FVector(-1200.0, 0.0, 0.0);
			CamImpulse.Dampening = 0.6;
			CamImpulse.ExpirationForce = 80.0;

			Player.ApplyCameraImpulse(CamImpulse, this);

			// UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(15.0, this, 0.75);
		}
	}
}

