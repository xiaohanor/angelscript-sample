class USpaceWalkResolver : USweepingMovementResolver
{
	bool CanPerformGroundTrace() const override
	{
		return false;
	}
}

class USpaceWalkMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	USpaceWalkPlayerComponent SpaceComp;
	USpaceWalkOxygenPlayerComponent OxyComp;

	bool bHaveHookLocation;
	FVector PreviousHookLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);

		MoveComp.OverrideResolver(USpaceWalkResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHaveHookLocation = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ClearOffset(n"SpaceWalk");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			bool bHasThrustInput = false;
			if (HasControl())
			{
				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				if (Player.IsCapabilityTagBlocked(n"MovementInput"))
					Input = FVector2D::ZeroVector;
				else if (OxyComp.bHasRunOutOfOxygen)
					Input = FVector2D::ZeroVector;

				FVector WantedThrust;
			//	WantedThrust += MoveComp.WorldUp * Input.X;
				WantedThrust += Player.ViewRotation.RightVector * Input.Y;
				WantedThrust = WantedThrust.GetClampedToMaxSize(1.0);

				bHasThrustInput = Math::Abs(Input.Y) > 0.05;

				Movement.AddAcceleration(WantedThrust * SpaceWalk::ManueveringAcceleration);
				Movement.AddAcceleration(SpaceComp.AdjustAcceleration.Get());

				FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
				FVector VerticalVelocity = MoveComp.VerticalVelocity;

				float HorizontalSpeed = HorizontalVelocity.Size();
				if (HorizontalSpeed > SpaceWalk::MaximumHorizontalVelocityBeforeDrag)
				{
					float DraggedOverspeed = (HorizontalSpeed - SpaceWalk::MaximumHorizontalVelocityBeforeDrag) * Math::Pow(SpaceWalk::HorizontalDragFactor, DeltaTime);
					HorizontalVelocity = HorizontalVelocity.GetSafeNormal() * (SpaceWalk::MaximumHorizontalVelocityBeforeDrag + DraggedOverspeed);
				}

				float VerticalSpeed = VerticalVelocity.Size();
				if (VerticalSpeed > SpaceWalk::MaximumVerticalVelocityBeforeDrag)
				{
					float DraggedOverspeed = (VerticalSpeed - SpaceWalk::MaximumVerticalVelocityBeforeDrag) * Math::Pow(SpaceWalk::VerticalDragFactor, DeltaTime);
					VerticalVelocity = VerticalVelocity.GetSafeNormal() * (SpaceWalk::MaximumVerticalVelocityBeforeDrag + DraggedOverspeed);
				}

				FVector Velocity = HorizontalVelocity + VerticalVelocity;
				Movement.AddVelocity(Velocity);

				Movement.AddPendingImpulses();

				if (!Velocity.IsNearlyZero())
				{
					Movement.InterpRotationTo(FQuat::MakeFromZX(MoveComp.WorldUp, Velocity), PI);

					FQuat Rotation = Math::QInterpConstantTo(
						Player.Mesh.WorldRotation.Quaternion(),
						FQuat::MakeFromZX(MoveComp.WorldUp, Velocity),
						DeltaTime, PI,
					);
					Player.MeshOffsetComponent.SnapToRotation(
						n"SpaceWalk", Rotation
					);
				}
			}
			// Remote update
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
};