struct FDentistToothDashActivateParams
{
	FVector DashImpulse;
	UDentistToothDashAutoAimComponent DashTarget;
};

struct FDentistToothDashDeactivateParams
{
	EDentistToothDashRecoveryState Recovery;
};

class UDentistToothDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(Dentist::Tags::Dash);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 101;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDashComponent DashComp;
	UDentistToothGroundPoundComponent GroundPoundComp;
	UDentistToothJumpComponent JumpComp;

	UPlayerMovementComponent MoveComp;
	UDentistToothDashMovementData MoveData;
	UPlayerTargetablesComponent TargetablesComp;

	float SpinAngle;

	float LastHitOtherPlayerTime = 0;
	FVector InitialHorizontalDashDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);
		JumpComp = UDentistToothJumpComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UDentistToothDashMovementData);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothDashActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!DashComp.ShouldDash())
			return false;

		// Don't allow a dash immediately after a jump
		if(JumpComp.StartedJumpingThisOrLastFrame())
			return false;

		Params.DashTarget = TargetablesComp.GetPrimaryTarget(UDentistToothDashAutoAimComponent);

		FVector DashDirection;
		if(Params.DashTarget != nullptr)
		{
			// Auto aim
			DashDirection = (Params.DashTarget.WorldLocation - Player.ActorCenterLocation).GetSafeNormal2D(FVector::UpVector);
		}
		else if(!MoveComp.MovementInput.IsNearlyZero())
		{
			// Dash in input direction
			DashDirection = MoveComp.MovementInput.GetSafeNormal2D(FVector::UpVector);
		}
		else
		{
			// Dash forward
			DashDirection = Player.ActorForwardVector.GetSafeNormal2D(FVector::UpVector);
		}

		// Rotate dash direction slightly upwards
		FVector RightVector = FVector::UpVector.CrossProduct(DashDirection).GetSafeNormal();
		DashDirection = FQuat(RightVector, Math::DegreesToRadians(-DashComp.Settings.DashAngle)) * DashDirection;

		Params.DashImpulse = DashDirection * DashComp.Settings.DashImpulse;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothDashDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
		{
			Params.Recovery = EDentistToothDashRecoveryState::None;
			return true;
		}

		if(!DashComp.IsDashing())
		{
			Params.Recovery = EDentistToothDashRecoveryState::None;
			return true;
		}

		if(DashComp.ShouldBackFlipOutOfDash())
		{
			Params.Recovery = EDentistToothDashRecoveryState::Backflipping;
			return true;
		}

		if(!MoveComp.IsInAir())
		{
			Params.Recovery = EDentistToothDashRecoveryState::Landing;
			return true;
		}

		if(GroundPoundComp.IsGroundPounding())
		{
			Params.Recovery = EDentistToothDashRecoveryState::None;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothDashActivateParams Params)
	{
		Player.SetActorVelocity(Params.DashImpulse);

		DashComp.OnStartDash(this, Params.DashTarget);

		const FVector DashDirection = Params.DashImpulse.GetSafeNormal();

		const FQuat VelocityRotation = FQuat::MakeFromZX(DashDirection, FVector::UpVector).Inverse();
		const FQuat RotationOffset = PlayerComp.GetMeshWorldRotation() * VelocityRotation.Inverse();
		SpinAngle = RotationOffset.GetTwistAngle(DashDirection);

		JumpComp.ResetChainedJumpCount();
		JumpComp.ResetJumpGracePeriod();

		InitialHorizontalDashDirection = Params.DashImpulse.GetSafeNormal2D(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothDashDeactivateParams Params)
	{
		DashComp.OnStopDash(Params.Recovery);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			if(DashComp.DashTarget != nullptr)
			{
				FVector ToDashTarget = (DashComp.DashTarget.WorldLocation - Player.ActorCenterLocation).GetSafeNormal2D();
				if(ToDashTarget.DotProduct(InitialHorizontalDashDirection) < 0)
				{
					// We have gone past the dash target!
					// Clear it
					DashComp.DashTarget = nullptr;
				}
			}

			ControlMovement(DeltaTime);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		FVector PreviousLocation = Player.ActorLocation;

		float LeftFF = Math::Sin(Time::GetGameTimeSeconds() * 0.0001);
		float RightFF = Math::Sin(-Time::GetGameTimeSeconds() * 0.0001);
		Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);

		TickMeshRotation(DeltaTime);

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);

		if(HasControl())
		{
			BroadcastDashMovementImpacts();
		}
	}

	private void ControlMovement(float DeltaTime)
	{
		check(HasControl());

		MoveData.AddPendingImpulses();
		MoveData.AddOwnerVerticalVelocity();

		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		FVector HorizontalDelta = HorizontalVelocity * DeltaTime;

		if(DashComp.Settings.DashHorizontalAcceleration > 0 && HorizontalVelocity.Size() > DashComp.Settings.DashMinimumHorizontalVelocity)
		{
			FVector Input = MoveComp.MovementInput;
			if(DashComp.DashTarget != nullptr)
			{
				Input = FVector::ZeroVector;
				//Input = (DashComp.DashTarget.WorldLocation - Player.ActorCenterLocation).GetSafeNormal2D(FVector::UpVector);
			}

			if(!Input.IsNearlyZero())
			{
				if(!HorizontalVelocity.IsNearlyZero())
				{
					const FVector HorizontalDirection = HorizontalVelocity.GetSafeNormal();

					// If we are inputting in the direction of our horizontal velocity, clamp it to not accelerate more
					if(Input.DotProduct(HorizontalDirection) > 0)
						Input = Input.VectorPlaneProject(HorizontalDirection);
				}

				const FVector HorizontalAcceleration = Input * DashComp.Settings.DashHorizontalAcceleration;
				Acceleration::ApplyAccelerationToVelocity(HorizontalVelocity, HorizontalAcceleration, DeltaTime, HorizontalDelta);
			}
		}

		float HorizontalSpeed = HorizontalVelocity.Size();
		if(HorizontalSpeed < DashComp.Settings.DashMinimumHorizontalVelocity
		&& HorizontalSpeed > 0) // Breaks if 0 speed
		{
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, DashComp.Settings.DashMinimumHorizontalVelocity, DeltaTime, DashComp.Settings.DashHorizontalAcceleration, HorizontalDelta);
		}

		MoveData.AddDeltaWithCustomVelocity(HorizontalDelta, HorizontalVelocity);

		MoveData.AddGravityAcceleration(false);

		FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, HorizontalVelocity);
		MoveData.SetRotation(Rotation);
	}

	private void TickMeshRotation(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		const float RotationSpeed = DashComp.Settings.DashRotationSpeedOverDurationCurve.GetFloatValue(DashComp.GetDashDuration());
		SpinAngle += RotationSpeed * DeltaTime;

		const FQuat VelocityRotation = FQuat::MakeFromZX(MoveComp.Velocity.GetSafeNormal(), FVector::UpVector);
		const FQuat SpinRelativeRotation = FQuat(FVector::UpVector, SpinAngle);

		FQuat Rotation = VelocityRotation * SpinRelativeRotation;

		if(Dentist::Dash::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Rotation, this, -1, DeltaTime);
	}

	private void BroadcastDashMovementImpacts()
	{
		for(auto Impact : MoveComp.AllImpacts)
		{
			auto MovementResponseComponent = UDentistToothMovementResponseComponent::Get(Impact.Actor);
			if(MovementResponseComponent == nullptr)
				continue;

			// FB TODO: Proper impulse
			MovementResponseComponent.OnDashedInto.Broadcast(Player, MoveComp.PreviousVelocity, Impact.ConvertToHitResult());
		}
	}
};