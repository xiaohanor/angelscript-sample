class UMoonMarketYarnBallMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;

	AMoonMarketYarnBall Ball;
	UHazeMovementComponent MoveComp;
	UMoonMarketYarnBallMovementData MoveData;
	const float MaxAcceleration = 800;
	const float MaxVerticalVelocity = 1400;
	const float MaxHorizontalVelocity = 2000;

	const float DisableRangeSqr = 8000 * 8000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<AMoonMarketYarnBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveComp.SetupShapeComponent(Ball.Collision);
		MoveData = MoveComp.SetupMovementData(UMoonMarketYarnBallMovementData);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!Ball.bEnabled)
			return false;

		if(Ball.ControllingPlayer == nullptr && Game::GetDistanceSquaredFromLocationToClosestPlayer(Owner.ActorLocation) >= DisableRangeSqr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Ball.Collision.ScaledSphereRadius == 0)
			return true;

		if(!Ball.bEnabled)
			return true;

		if(Ball.ControllingPlayer == nullptr && Game::GetDistanceSquaredFromLocationToClosestPlayer(Owner.ActorLocation) >= DisableRangeSqr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(IsValid(Ball.ControllingPlayer))
			CapabilityInput::LinkActorToPlayerInput(Ball, Ball.ControllingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Ball.Collision.ScaledSphereRadius == 0)
			return;

		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			CalculateMovement(DeltaTime);
		}
		else
		{
			MoveData.ApplyRemoteSideEvaluateGround();
			if(MoveComp.IsOnAnyGround())
				MoveData.ApplyCrumbSyncedGroundMovement();
			else
				MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void CalculateMovement(float DeltaTime)
	{
		const float HorizontalSpeedGroundAcceleration = 5;
		const float HorizontalSpeedGroundDeceleration = 2;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		FVector VerticalVelocity = MoveComp.VerticalVelocity;

		if(IsValid(Ball.ControllingPlayer))
		{
			FVector Forward = Ball.ControllingPlayer.GetCameraDesiredRotation().ForwardVector.VectorPlaneProject(FVector::UpVector);
			FVector Right = Forward.CrossProduct(FVector::UpVector);

			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if(!Math::IsNearlyZero(Input.Size()))
			{
				FVector TargetVelocity = Forward * Input.X * MaxAcceleration + Right * -Input.Y * MaxAcceleration;
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, TargetVelocity, DeltaTime, HorizontalSpeedGroundAcceleration);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, HorizontalSpeedGroundDeceleration);
			}
		}
		else
		{
			if(MoveComp.HasGroundContact() && !Math::IsNearlyZero(HorizontalVelocity.Size()))
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, HorizontalSpeedGroundDeceleration);
		}
		
		MoveData.AddPendingImpulses();
		MoveData.AddGravityAcceleration();
		
		if(Math::IsNearlyZero(HorizontalVelocity.Size()) && Math::IsNearlyZero(VerticalVelocity.Size()))
				return;

		if(HorizontalVelocity.Size() > MaxHorizontalVelocity)
		{
			HorizontalVelocity = HorizontalVelocity.GetSafeNormal() * Math::Clamp(HorizontalVelocity.Size(), 0, MaxHorizontalVelocity);
		}
		if(VerticalVelocity.Size() > MaxVerticalVelocity)
		{
			VerticalVelocity = VerticalVelocity.GetSafeNormal() * Math::Clamp(VerticalVelocity.Size(), 0, MaxVerticalVelocity);
		}

		FVector Velocity = HorizontalVelocity + VerticalVelocity;
		MoveData.AddVelocity(Velocity);
	}
};