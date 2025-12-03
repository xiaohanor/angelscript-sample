class UMoonMarketSausageJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40; // Tick before player jump

	AMoonMarketSausage Sausage;

	UPlayerAirMotionComponent AirMotionComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UHazeOffsetComponent MeshOffsetComponent;
	UMoonMarketSausageMovementSettings Settings;

	UMoonMarketShapeshiftComponent ShapeshiftComp;

	const float MaxTangentHeight = 150.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AirMotionComponent = UPlayerAirMotionComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();
		ShapeshiftComp = UMoonMarketShapeshiftComponent::Get(Player);
		Settings = UMoonMarketSausageMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (MovementComponent.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Sausage = Cast<AMoonMarketSausage>(UMoonMarketShapeshiftComponent::Get(Player).ShapeshiftShape.CurrentShape);
		// Add impulse and set velocity
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(Sausage, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(Owner, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
		FVector InitialHorizontalVelocity = MovementComponent.HorizontalVelocity.GetSafeNormal() * Math::Min(Settings.ForwardSpeed * MovementComponent.MovementInput.Size(), MovementComponent.HorizontalVelocity.Size());
		FVector InitialVerticalVelocity = MovementComponent.WorldUp * Settings.JumpImpulse;
		Player.SetActorHorizontalAndVerticalVelocity(InitialHorizontalVelocity, InitialVerticalVelocity);
		MeshOffsetComponent = Sausage.MeshOffsetComponent;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MeshOffsetComponent.ResetOffsetWithLerp(this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(MovementComponent.MovementInput, MovementComponent.HorizontalVelocity, DeltaTime);
				AirControlVelocity = AirControlVelocity.GetSafeNormal() * Math::Min(AirControlVelocity.Size(), Settings.ForwardSpeed);
				MoveData.AddHorizontalVelocity(AirControlVelocity);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				FQuat Rotation = GetTargetRotation();
				float InterpSpeed = MovementComponent.MovementInput.Size() + KINDA_SMALL_NUMBER;
				MoveData.InterpRotationTo(Rotation, 10 * InterpSpeed, false);
				
				MoveData.RequestFallingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			const float FloppyJumpFraction = 1.0 - Math::Saturate(ActiveDuration / 0.2);

			// Reset mesh offset over time
			Sausage.SplineMesh.RelativeLocation = Sausage.SplineMesh.RelativeLocation * FloppyJumpFraction;

			UpdateTangents(FloppyJumpFraction, DeltaTime);
		}
	}
	
	FQuat GetTargetRotation() const
	{
		FVector FacingDirection = FVector::ZeroVector;
		if (MovementComponent.MovementInput.IsNearlyZero())
			FacingDirection = Player.ActorForwardVector;
		else
			FacingDirection = MovementComponent.MovementInput;

		// Flip forward if heading the other way
		if (FacingDirection.DotProduct(Player.ActorForwardVector) < 0)
			FacingDirection = -FacingDirection;

		return FQuat::MakeFromX(FacingDirection);
	}

	// Eman TODO: Constrain acceleration delta or substep
	void UpdateTangents(float FloppyFraction, float DeltaTime)
	{
		float TangentHeight = MaxTangentHeight * FloppyFraction;
		float Stiffness = Math::Max(1000 * FloppyFraction, 300);
		float Damping = 0.2;

		// float MinDeltaTime = 0.01666;
		// float MaxDeltaTime = 0.03333;
		// float ConstrainedDeltaTime = Math::Clamp(DeltaTime, MinDeltaTime, MaxDeltaTime);

		FVector StartTangent = Sausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * TangentHeight;
		Sausage.AcceleratedStartTangent.SpringTo(StartTangent, Stiffness, Damping, DeltaTime);

		FVector EndTangent = Sausage.GetEndTangent() * FVector::ForwardVector - FVector::UpVector * TangentHeight;
		Sausage.AcceleratedEndTangent.SpringTo(EndTangent, Stiffness, Damping, DeltaTime);

		Sausage.UpdateTangents();
	}
}