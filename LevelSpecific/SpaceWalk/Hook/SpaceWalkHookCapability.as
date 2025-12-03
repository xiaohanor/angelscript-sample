struct FSpaceWalkHookActivationParameters
{
	USpaceWalkHookPointComponent PointComp;
}

struct FSpaceWalkHookDeactivationParameters
{
	bool bReleasedButton = false;
}

class USpaceWalkHookCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	USpaceWalkPlayerComponent SpaceComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	USpaceWalkHookPointComponent HookPoint;

	const float MinimumTimeBeforeCancel = 0.25;
	const float AdjustForce = 2000.0;
	const float AdjustMaxVelocity = 2000.0;

	const float HookAttachDuration = 0.2;
	const float HookReturnDuration = 0.1;
	FVector HookAttachOffset;

	FVector AdjustInAcceleration;
	bool bHasLaunched = false;
	bool bHasReachedTarget = false;

	FVector LastHookPointLocation;
	FVector LastFrameActorLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);

		SpaceComp.Hook = SpawnActor(SpaceComp.HookClass);
		SpaceComp.Hook.Player = Player;
		SpaceComp.Hook.SetActorHiddenInGame(true);
		SpaceComp.Hook.SpaceComp = SpaceComp;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && SpaceComp.Hook.bAvailable && !IsBlocked())
		{
			FTargetableWidgetSettings WidgetSettings;
			WidgetSettings.TargetableClass = USpaceWalkHookPointComponent;
			WidgetSettings.DefaultWidget = SpaceComp.HookPointWidget;
			WidgetSettings.MaximumVisibleWidgets = 1;
			WidgetSettings.bAllowAttachToEdgeOfScreen = false;

			PlayerTargetablesComp.ShowWidgetsForTargetables(WidgetSettings);
		}

		if (!SpaceComp.Hook.bAttached && !SpaceComp.Hook.bAvailable)
		{
			FVector TargetLocation = Player.Mesh.GetSocketLocation(SpaceComp.GetHookLaunchSocket());


			float InitialDistance = HookAttachOffset.Size();
			float CurrentDistance = SpaceComp.Hook.ActorLocation.Distance(TargetLocation);
			float Acceleration = Math::Max(2.0 * InitialDistance / HookReturnDuration, 2.0 * CurrentDistance / Math::Max(0.01, HookReturnDuration - DeactiveDuration));
			float ReturnSpeed = Acceleration * DeactiveDuration;

			SpaceComp.Hook.ActorLocation = Math::VInterpConstantTo(
				SpaceComp.Hook.ActorLocation,
				TargetLocation,
				DeltaTime, ReturnSpeed
			);

			if (SpaceComp.Hook.ActorLocation.Equals(TargetLocation, 1.0))
			{
				SpaceComp.Hook.bAvailable = true;
				SpaceComp.bIsHookReturning = false;
				SpaceComp.Hook.SetActorHiddenInGame(true);
				USpaceWalkZeroGEffectHandler::Trigger_OnHookFinishedRetracting(Player);
			}
			else
			{
				SpaceComp.bIsHookReturning = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSpaceWalkHookActivationParameters& Parameters) const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!SpaceComp.Hook.bAvailable)
			return false;

		auto PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(USpaceWalkHookPointComponent);
		if (PrimaryTarget == nullptr)
			return false;

		Parameters.PointComp = Cast<USpaceWalkHookPointComponent>(PrimaryTarget);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSpaceWalkHookDeactivationParameters& Parameters) const
	{
		if (bHasReachedTarget)
			return true;

		if (!IsValid(HookPoint))
			return true;

		if (ActiveDuration > MinimumTimeBeforeCancel)
		{
			if (!IsActioning(ActionNames::PrimaryLevelAbility))
			{
				Parameters.bReleasedButton = true;
				return true;
			}
		}

		if (SpaceWalk::bDetachWhenHittingCollision)
		{
			if (MoveComp.HasImpactedWall())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSpaceWalkHookActivationParameters Parameters)
	{
		HookPoint = Parameters.PointComp;
		bHasLaunched = false;
		bHasReachedTarget = false;
		LastFrameActorLocation = Player.ActorLocation;

		SpaceComp.Hook.AttachRootComponentTo(HookPoint);
		SpaceComp.Hook.SetActorHiddenInGame(false);
		SpaceComp.Hook.bAttached = true;
		SpaceComp.Hook.bAvailable = false;

		SpaceComp.TargetHookPoint = HookPoint;
		SpaceComp.bHasHookLaunched = true;
		SpaceComp.bHasHookAttached = false;
		SpaceComp.bHookForceRelease = false;
		SpaceComp.HookLaunchYaw = FRotator::MakeFromX(Player.ActorTransform.InverseTransformPosition(HookPoint.WorldLocation)).Yaw;
		SpaceComp.bLaunchedFromLeftHand = SpaceComp.HookLaunchYaw < -15.0;

		FVector HookStartLocation = Player.Mesh.GetSocketLocation(SpaceComp.GetHookLaunchSocket());
		SpaceComp.Hook.SetActorLocationAndRotation(
			HookStartLocation, 
			FRotator::MakeFromX(HookPoint.WorldLocation - HookStartLocation)
		);
		HookAttachOffset = SpaceComp.Hook.ActorRelativeLocation;

		USpaceWalkZeroGEffectHandler::Trigger_OnHookLaunched(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("TargetHookPoint", SpaceComp.TargetHookPoint);
		TemporalLog.Value("bHasHookLaunched", SpaceComp.bHasHookLaunched);
		TemporalLog.Value("bHasHookAttached", SpaceComp.bHasHookAttached);
		TemporalLog.Value("bIsHookReturning", SpaceComp.bIsHookReturning);
		TemporalLog.Value("bHookForceRelease", SpaceComp.bHookForceRelease);
		TemporalLog.Value("HookLaunchYaw", SpaceComp.HookLaunchYaw);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSpaceWalkHookDeactivationParameters Parameters)
	{
		SpaceComp.Hook.bAttached = false;
		SpaceComp.Hook.DetachRootComponentFromParent();
		HookAttachOffset = Player.Mesh.GetSocketLocation(SpaceComp.GetHookLaunchSocket()) - SpaceComp.Hook.ActorLocation;
		Player.MeshOffsetComponent.ClearOffset(n"SpaceWalk");

		if (bHasLaunched)
			USpaceWalkZeroGEffectHandler::Trigger_OnHookDetached(Player);

		SpaceComp.TargetHookPoint = nullptr;
		SpaceComp.bHasHookLaunched = false;
		SpaceComp.bHasHookAttached = false;
		SpaceComp.bHookForceRelease = !Parameters.bReleasedButton;
		SpaceComp.bIsHookReturning = true;
	}

	void TriggerLaunch()
	{
		bHasLaunched = true;
		LastHookPointLocation = HookPoint.WorldLocation;
		Player.PlayForceFeedback(SpaceComp.HookAttachFF, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasLaunched)
		{
			if (ActiveDuration >= HookAttachDuration)
			{
				USpaceWalkZeroGEffectHandler::Trigger_OnHookAttached(Player);
				SpaceComp.bHasHookAttached = true;
				SpaceComp.Hook.ActorRelativeLocation = FVector::ZeroVector;
				TriggerLaunch();
			}
			else
			{
				float HookAlpha = Math::EaseIn(0.0, 1.0, ActiveDuration / HookAttachDuration, 2.0);
				SpaceComp.Hook.ActorRelativeLocation = HookAttachOffset * (1.0 - HookAlpha);
			}
		}
		
		FVector PreviousActorLocation = Player.ActorLocation;
		if (bHasLaunched)
		{
			bool bHasThrustInput = false;

			if (MoveComp.PrepareMove(Movement))
			{
				FVector HookDirection = (HookPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
				if (HasControl())
				{
					FVector Velocity = MoveComp.Velocity;
					if (SpaceWalk::bCancelBackwardsVelocityWhenAttaching)
					{
						if (Velocity.DotProduct(HookDirection) < 0)
							Velocity = Velocity.ConstrainToPlane(HookDirection);
					}

					FVector LateralVelocity = Velocity.ConstrainToPlane(HookDirection);

					bool bDragLateralVelocity = true;
					if (HookPoint.bUseAutoLaunchCone)
					{
						const float ErrorDegrees = HookPoint.ForwardVector.GetAngleDegreesTo(HookDirection);
						const bool bIsInLaunchCone = ErrorDegrees < HookPoint.AutoLaunchConeAngle + HookPoint.AutoLaunchMaxTriggerAngle;
						if (bIsInLaunchCone)
						{
							FVector AdjustedVector = HookDirection.ConstrainToCone(HookPoint.ForwardVector, Math::DegreesToRadians(HookPoint.AutoLaunchConeAngle));
							FVector AdjustTargetPoint = Math::ClosestPointOnInfiniteLine(
								HookPoint.WorldLocation, HookPoint.WorldLocation-AdjustedVector,
								Player.ActorLocation
							);

							FVector AdjustDirection = (AdjustTargetPoint - Player.ActorLocation).GetSafeNormal();
							if (AdjustDirection.IsNearlyZero())
								AdjustDirection = LateralVelocity.GetSafeNormal();

							float AdjustSpeed = Velocity.DotProduct(AdjustDirection);

							float TimeToHookPoint = Trajectory::GetTimeToReachTarget(
								HookPoint.WorldLocation.Distance(Player.ActorLocation),
								Velocity.DotProduct(HookDirection), HookPoint.ExitVelocity,
								HookPoint.HookAcceleration,
							);

							if (TimeToHookPoint > 0 && !AdjustDirection.IsNearlyZero())
							{
								float DistanceToAdjust = AdjustTargetPoint.Distance(Player.ActorLocation);
								float WantedAdjustSpeed = Math::Min(DistanceToAdjust / (TimeToHookPoint * 0.5), AdjustMaxVelocity);
								float NewAdjustSpeed = Math::FInterpConstantTo(AdjustSpeed, WantedAdjustSpeed, DeltaTime, AdjustForce);

								TEMPORAL_LOG(this)
									.DirectionalArrow("AdjustDirection", Player.ActorLocation, AdjustDirection * AdjustForce)
									.DirectionalArrow("CurrentForward", HookPoint.WorldLocation, HookDirection * 500)
									.DirectionalArrow("WantedForward", HookPoint.WorldLocation, AdjustedVector * 500)
									.Point("AdjustTargetPoint", AdjustTargetPoint)
									.Value("TimeToHookPoint", TimeToHookPoint)
									.Value("AdjustSpeed", AdjustSpeed)
									.Value("NewAdjustSpeed", AdjustSpeed)
								;

								Movement.AddVelocity(AdjustDirection * (NewAdjustSpeed - AdjustSpeed));

								LateralVelocity = LateralVelocity.ConstrainToDirection(AdjustDirection)
									+ LateralVelocity.ConstrainToPlane(AdjustDirection) * Math::Pow(SpaceWalk::HookLateralVelocityDragWhenForcingAutoCone, DeltaTime);
								bDragLateralVelocity = false;
							}
						}
					}

					float HookSpeed = Velocity.DotProduct(HookDirection);
					HookSpeed = Math::FInterpConstantTo(HookSpeed, HookPoint.ExitVelocity, DeltaTime, HookPoint.HookAcceleration);

					Movement.AddVelocity(HookDirection * HookSpeed);
					Movement.InterpRotationTo(FQuat::MakeFromZX(MoveComp.WorldUp, Velocity), PI);

					float FFFrequency = 60.0;
					float FFIntensity = 0.1;
					FHazeFrameForceFeedback FF;
					//	FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
						FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
						Player.SetFrameForceFeedback(FF);

					if (bDragLateralVelocity)
						LateralVelocity *= Math::Pow(SpaceWalk::HookLateralVelocityDrag, DeltaTime);
					Movement.AddVelocity(LateralVelocity);

					// Add Velocity from maneuvering
					FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

					FVector HookRight = HookDirection.CrossProduct(-FVector::UpVector);
					FVector HookUp = HookRight.CrossProduct(HookDirection);

					FVector WantedThrust;
				//	WantedThrust += HookUp * -Input.X;
					WantedThrust += HookRight * Input.Y;
					WantedThrust = WantedThrust.GetClampedToMaxSize(1.0);
					Movement.AddAcceleration(WantedThrust * SpaceWalk::HookAttachedManeuveringAcceleration);

					bHasThrustInput = Math::Abs(Input.Y) > 0.05;

					// Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + WantedThrust * SpaceWalk::HookAttachedManeuveringAcceleration, FLinearColor::Red);

					FQuat Rotation = Math::QInterpConstantTo(
						Player.Mesh.WorldRotation.Quaternion(),
						FQuat::MakeFromZX(MoveComp.WorldUp, Velocity),
						DeltaTime, PI,
					);
					Player.MeshOffsetComponent.SnapToRotation(
						n"SpaceWalk", Rotation
					);

					if (SpaceWalk::bReceiveVelocityFromHookPointMoving)
					{
						FVector HookPointMovement = HookPoint.WorldLocation - LastHookPointLocation;
						float HookLineMovement = HookPointMovement.DotProduct(HookDirection);
						float HookSpeedMovement = HookSpeed * DeltaTime;
						if (HookLineMovement > 0 && HookLineMovement > HookSpeedMovement)
						{
							Movement.AddDelta(HookDirection * (HookLineMovement - Math::Max(HookSpeedMovement, 0)));
						}
					}
				}
				else
				{
					Movement.ApplyCrumbSyncedAirMovement();
					bHasThrustInput = MoveComp.GetSyncedLocalSpaceMovementInputForAnimationOnly().Size() > 0.05;
				}

				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ZeroG");
				
				if (bHasThrustInput != SpaceComp.bIsThrusting)
				{
					if (bHasThrustInput)
						USpaceWalkZeroGEffectHandler::Trigger_OnStartedThrusting(Player);
					else
						USpaceWalkZeroGEffectHandler::Trigger_OnStoppedThrusting(Player);
					SpaceComp.bIsThrusting = bHasThrustInput;
				}
			}
		}
		else
		{
			PreviousActorLocation = LastFrameActorLocation;
		}

		if (HasControl())
		{
			if (SpaceWalk::bDetachWhenPassingHookPoint && !Player.ActorVelocity.IsNearlyZero())
			{
				// When we cross past the hook point, cancel the hook automatically
				FPlane ExitPlane = FPlane(HookPoint.WorldLocation, Player.ActorVelocity);
				float PreviousPlaneDot = ExitPlane.PlaneDot(PreviousActorLocation);
				float NewPlaneDot = ExitPlane.PlaneDot(Player.ActorLocation);

				if (Math::Sign(PreviousPlaneDot) != Math::Sign(NewPlaneDot))
				{
					Player.PlayForceFeedback(SpaceComp.HookLetGoFF, false, false,this);
					bHasReachedTarget = true;
				}
				
			}
		}

		LastHookPointLocation = HookPoint.WorldLocation;
		LastFrameActorLocation = Player.ActorLocation;
	}
};