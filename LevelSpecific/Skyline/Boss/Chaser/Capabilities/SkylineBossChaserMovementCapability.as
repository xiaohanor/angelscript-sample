class USkylineBossChaserMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineBossChaser Chaser;

	UHazeMovementComponent MoveComp;

	USweepingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Chaser = Cast<ASkylineBossChaser>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement, -Chaser.GravityDirection))
		{
			float Drag = Chaser.Settings.AirDrag;
			float ForceScale = Chaser.Settings.AirControl;

			FVector Velocity = MoveComp.Velocity;

			FVector Force = FVector::ZeroVector;
			FQuat DesiredRotation = Velocity.ToOrientationQuat();

			if (!Chaser.CurrentTarget.IsDefaultValue())
			{
			//	FVector TargetLocation = Chaser.CurrentTarget.Get().ActorLocation;
				FVector TargetLocation = Chaser.CurrentTarget.Get().ActorTransform.TransformPositionNoScale(Chaser.TargetOffset);

				FVector ToTarget = TargetLocation - Chaser.ActorLocation;

				FVector LeanVector = Velocity.SafeNormal.CrossProduct(ToTarget.SafeNormal);

				float Lean = Chaser.Settings.MaxLeanAngle * LeanVector.DotProduct(Chaser.ActorUpVector);

				Chaser.Pivot.RelativeRotation = FRotator(0.0, 0.0, Lean);

				if (MoveComp.IsOnAnyGround())
				{
					Drag = Chaser.Settings.GroundDrag;
					ForceScale = 1.0;
					ToTarget = ToTarget.VectorPlaneProject(MoveComp.CurrentGroundNormal);
					DesiredRotation = ToTarget.ToOrientationQuat();
				}

			//	Force = ToTarget.SafeNormal * Math::Min(Chaser.Settings.Speed, ToTarget.Size());
				Force = ToTarget.SafeNormal * Chaser.Settings.Speed;
			}

			FVector Acceleration = Force * ForceScale
								 + Chaser.GravityDirection * Chaser.Settings.Gravity
								 - Velocity * Drag;

			Velocity += Acceleration * DeltaTime;

			FQuat Rotation = FQuat::Slerp(Chaser.ActorQuat, DesiredRotation, 6.0 * DeltaTime);
		
			Movement.AddVelocity(Velocity);
			Movement.SetRotation(Rotation);
			MoveComp.ApplyMove(Movement);

			if (MoveComp.HasGroundContact() && MoveComp.WasInAir())
			{
				Owner.ActorVelocity = GetVelocityFromBounce(Velocity, Chaser.Settings.GroundBounce, MoveComp.GroundContact.Normal);
				FSkylineBossChaserEventData Data;
				Data.HitResult = MoveComp.GroundContact.ConvertToHitResult();
				Data.Velocity = Velocity;
				USkylineBossChaserEventHandler::Trigger_GroundImpact(Owner, Data);
			}

			if (MoveComp.HasWallContact())
			{
				Owner.ActorVelocity = GetVelocityFromBounce(Velocity, Chaser.Settings.WallBounce, MoveComp.WallContact.Normal);
				FSkylineBossChaserEventData Data;
				Data.HitResult = MoveComp.WallContact.ConvertToHitResult();
				Data.Velocity = Velocity;
				USkylineBossChaserEventHandler::Trigger_WallImpact(Owner, Data);
			}

		//	FLinearColor Color = (MoveComp.IsOnAnyGround() ? FLinearColor::Green : FLinearColor::Red);
		//	Debug::DrawDebugSphere(Chaser.ActorLocation, 410.0, 24, Color, 5.0, 0.0);
		//	Debug::DrawDebugLine(ActorLocation, ActorLocation + DesiredRotation.ForwardVector * 500.0, FLinearColor::Red, 50.0, 0.0);
		}
	}

	FVector GetVelocityFromBounce(FVector Velocity, float Restitution, FVector Normal)
	{
		float d = Velocity.DotProduct(Normal);
		float j = Math::Max(-(1 + Restitution) * d, 0.0);

		return Velocity + Normal * j;
	}
};