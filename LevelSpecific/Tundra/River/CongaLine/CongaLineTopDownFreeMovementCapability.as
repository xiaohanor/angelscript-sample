
class UCongaLineTopDownFreeMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	default CapabilityTags.Add(CongaLine::Tags::CongaLineMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 101;

	UCongaLinePlayerComponent CongaComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CongaComp = UCongaLinePlayerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSteppingMovementData();
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CongaLine::GetManager().bIsSnake)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CongaLine::GetManager().bIsSnake)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			/**
			 * Gravity might not be necessary since the floor is entirely flat, but this just makes sure the player is grounded.
			 */
			MoveData.AddOwnerVelocity();
			MoveData.AddGravityAcceleration();

			FVector MovementInput = MoveComp.MovementInput;

				ApplyMovementVelocity(MovementInput, DeltaTime);
				ApplyFriction(DeltaTime);
				MoveData.AddPendingImpulses();
				if(!MoveComp.HorizontalVelocity.IsNearlyZero() && !MovementInput.IsNearlyZero())
					MoveData.SetRotation(Math::QInterpConstantTo(Player.GetActorQuat(), MoveComp.HorizontalVelocity.ToOrientationQuat(), DeltaTime, CongaLine::RotationInterpSpeed));

			/**
			* Check if we are colliding with the conga line
			* The implementation is dirt simple and very unoptimized
			*/
			CongaComp.CheckCollisionWithCongaLine();

			// const FVector Forward = Rotation.ForwardVector.VectorPlaneProject(FVector::UpVector);
			// const float Speed = CongaComp.GetSpeed(Forward, DeltaTime);
			// const FVector Velocity = Forward * Speed;
			// MoveData.AddVelocity(Velocity);
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		/**
		 * Requesting SnowMonkeyConga makes sure that the animation feature with that tag is used
		 * @see ULocomotionFeatureSnowMonkeyConga
		 */
		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, n"CongaMovement");
	}

	void ApplyMovementVelocity(FVector MovementInput, float DeltaTime)
	{
		float CurrentAcceleration = Math::Lerp(CongaLine::MinGroundMovementAcceleration, CongaLine::GroundMovementAcceleration, MovementInput.Size());
		MoveData.AddHorizontalVelocity(MovementInput.GetSafeNormal() * (CurrentAcceleration * DeltaTime));
	}

	void ApplyFriction(float DeltaTime)
	{
		float FrictionValue = CongaLine::HorizontalGroundFriction;
		MoveData.AddHorizontalVelocity(-MoveComp.HorizontalVelocity * (FrictionValue * DeltaTime));
	}
};