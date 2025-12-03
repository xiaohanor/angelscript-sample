class USummitDecimatorTopdownPermaKnockedOutCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AAISummitDecimatorTopdown Decimator;

	USummitDecimatorTopdownSettings Settings;
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	USummitDecimatorTopdownFollowSplineComponent SplineFollowComp;

	FVector SplineOffset;
	FQuat SplineAngularOffset;

	FSplinePosition SplinePos;

	FHazeAcceleratedFloat AccBiteJolt;
	float CurrentSpeed = 0.0;

	const float SplineOffsetInterpDownSpeed = 2500.0;
	const float SplineAngularOffsetInterpDownSpeed = 4.0;
	bool bHasBothPlayersBit = false;
	bool bHasBeenPushedToPanic = false;

	TPerPlayer<UPlayerMovementComponent> PlayerMoveComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		Decimator.LeftDragInteractionComp.Disable(this);
		Decimator.RightDragInteractionComp.Disable(this);

		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		SplineFollowComp = USummitDecimatorTopdownFollowSplineComponent::Get(Owner);
		Decimator.OnBothPlayersBit.AddUFunction(this, n"OnBothPlayersBit");
	}

	UFUNCTION()
	private void OnBothPlayersBit()
	{
		AccBiteJolt.SnapTo(400);
		bHasBothPlayersBit = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::PermaKnockedOut)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::PermaKnockedOut)
			return true;
		return false;
	}

	FQuat StartQuat;
	FQuat StartSplinePosQuat;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerMoveComps[Game::Mio] = UPlayerMovementComponent::Get(Game::Mio);
		PlayerMoveComps[Game::Zoe] = UPlayerMovementComponent::Get(Game::Zoe);
		// when starting from progress point Decimator Sad, Owner hasn't detached yet. Happens in start of phase 3.
		if (Owner.GetAttachParentActor() != nullptr )
			Owner.DetachFromActor(EDetachmentRule::KeepWorld);
		
		// Enter flipped animation state
		UBasicAIAnimationComponent AnimComp = UBasicAIAnimationComponent::Get(Owner);
		DecimatorTopdown::Animation::RequestFeaturePush(AnimComp, this);

		UBasicAIHealthBarComponent HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
        HealthBarComp.SetHealthBarEnabled(false);

		SplinePos = SplineFollowComp.Spline.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		SplineOffset = FVector(0, 0, 0);
		StartSplinePosQuat = FQuat::MakeFromXZ(SplinePos.WorldForwardVector, -SplinePos.WorldUpVector);
		SplineAngularOffset = Owner.ActorQuat - StartSplinePosQuat;

		StartQuat = Owner.ActorQuat;
		CurrentQuat = StartQuat;
		Decimator.LeftDragInteractionComp.Enable(this);
		Decimator.RightDragInteractionComp.Enable(this);

		USummitDecimatorTopdownEffectsHandler::Trigger_OnPermaKnockedOut(Decimator);
		DecimatorTopdown::Collision::SetPlayerBlockingCollision(Decimator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerMoveComps[Game::Mio].ClearMovementInput(this);
		PlayerMoveComps[Game::Zoe].ClearMovementInput(this);
		// DevReset
		//Owner.SetActorRotation(StartQuat);
		//Owner.SetActorLocation(SplinePos.WorldLocation);
	}

	FQuat CurrentQuat;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Handle player pushing input
		float PlayerInputSplineForwardAlignment = 0.0;
		bool bIsSoloPush = false;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!bHasBothPlayersBit)
				break;

			float Dot = SplineFollowComp.PlayerMovementInput[Player].DotProduct(SplinePos.WorldForwardVector);
			float RawInputY = SplineFollowComp.PlayerRawInput[Player].Y;
			
			// Not Aligned with forward or too little upwards raw input, ignoring input
			if(Dot < 0.1 &&  RawInputY < 0.3)
			{
				bIsSoloPush = true;
				// Animation checks for movementinput, if we don't push in direction of decimator zero it out
				PlayerMoveComps[Player].ApplyMovementInput(FVector::ZeroVector, this, EInstigatePriority::High);
				continue;
			}
			PlayerMoveComps[Player].ClearMovementInput(this);

			float PushFactor = Math::Max(Dot, 0.5);
			PushFactor = Math::Max(RawInputY, PushFactor);
			PlayerInputSplineForwardAlignment += PushFactor * 0.5;

			FHazeFrameForceFeedback FrameForceFeedback;
			if (Time::FrameNumber % 4 == 0)
			{
				FrameForceFeedback.LeftMotor = Math::Abs(Math::Sin(Time::GameTimeSeconds * 10)*0.4);
				FrameForceFeedback.RightMotor = Math::Abs(Math::Sin(Time::GameTimeSeconds * 10)*0.4);
			}
			Player.SetFrameForceFeedback(FrameForceFeedback, Intensity = 0.1);
		}

		if (bIsSoloPush)
			PlayerInputSplineForwardAlignment *= 0.5;

		// Rotate towards spline direction
		FQuat SplineQuat = FQuat::MakeFromXZ(-SplinePos.WorldForwardVector, SplinePos.WorldUpVector);
		CurrentQuat = Math::QInterpConstantTo(CurrentQuat, SplineQuat, DeltaTime, SplineAngularOffsetInterpDownSpeed);
		Owner.SetActorRotation(CurrentQuat);

		// Initial bite impulse
		AccBiteJolt.AccelerateTo(0.0, 2.5, DeltaTime);
		SplinePos.Move(AccBiteJolt.Value * DeltaTime);

		// Dynamic push movement
		float MaxAcceleration = 1500.0;

		float Friction = 2.5; // ground friction
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);
		CurrentSpeed += (MaxAcceleration * PlayerInputSplineForwardAlignment) * DeltaTime;		
		float GravityComponent = FVector(0, 0, -9.80).DotProduct(SplinePos.WorldForwardVector * -1.0) * 50.0; // Gravity component in hill climb. Extra strong gravity.
		CurrentSpeed -= GravityComponent * DeltaTime;
		CurrentSpeed *= FrictionFactor;
		
		SplinePos.Move(CurrentSpeed * DeltaTime);
		Owner.SetActorLocation(SplinePos.WorldLocation + SplineOffset);

		// Start more energetic struggle animation
		if (!bHasBeenPushedToPanic)
		{
			float Dist = SplineFollowComp.Spline.Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
			if (SplineFollowComp.Spline.Spline.SplineLength > 0 && Dist / SplineFollowComp.Spline.Spline.SplineLength > 0.5)
			{
				UBasicAIAnimationComponent AnimComp = UBasicAIAnimationComponent::Get(Owner);
				DecimatorTopdown::Animation::RequestFeaturePushPanic(AnimComp, this);
				bHasBeenPushedToPanic = true;
			}
		}
	}

	
};