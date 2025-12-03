class UTundraPlayerSnowMonkeyClimbableVineMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;
	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerSnowMonkeyClimbableVineComponent VineComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUserComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerSnowMonkeyClimbableVineSettings Settings;
	USweepingMovementData Movement;

	FHazeAcceleratedFloat AcceleratedVerticalInput;
	FVector CurrentLocation;
	FVector UpVector;

	FHazeAcceleratedVector AccParticle1;
	FHazeAcceleratedVector AccParticle2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		VineComp = UTundraPlayerSnowMonkeyClimbableVineComponent::GetOrCreate(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UTundraPlayerSnowMonkeyClimbableVineSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(VineComp.CurrentVine == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerSnowMonkeyClimbableVineMovementDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(VineComp.CurrentVine == nullptr)
			return true;

		if(WasActionStarted(ActionNames::Cancel))
			return true;

		if(WasActionStarted(ActionNames::MovementJump))
		{
			Params.bPressedJump = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentLocation = MonkeyAttachPoint;
		UpVector = MonkeyAttachUpVector;
		PoleClimbComp.AnimData.bClimbing = true;
		PoleClimbComp.AnimData.State = EPlayerPoleClimbState::Climbing;
		//UpdateFixedParticles();

		// snap accelerated positions
		AddAlphaToMonkeyPosition(0.0);
		FVector ParticlePos1 = VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex1].Position;
		FVector ParticlePos2 = VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex2].Position;
		AccParticle1.SnapTo(ParticlePos1);
		AccParticle2.SnapTo(ParticlePos2);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerSnowMonkeyClimbableVineMovementDeactivatedParams Params)
	{
		if(!IsBlocked())
		{
			FVector LocalImpulse = Params.bPressedJump ? Settings.JumpLeaveVineImpulse : Settings.BaseLeaveVineImpulse;
			FVector Impulse = Player.ActorTransform.TransformVectorNoScale(LocalImpulse);
			Player.SetActorVelocity(Impulse);
		}

		VineComp.TimeOfDetachFromVine = Time::GetGameTimeSeconds();

		VineComp.ResetFixedParticles();
		VineComp.ResetGravityForceOnParticles();

		AcceleratedVerticalInput.SnapTo(0.0);
		PoleClimbComp.AnimData.ResetData();

		VineComp.CurrentVine = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		VineComp.SetGravityForceOnParticles(Player.ActorCenterLocation, Settings.GravityForce);

		UpVector = Math::VInterpTo(UpVector, MonkeyAttachUpVector, DeltaTime, -8.0);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				AcceleratedVerticalInput.AccelerateTo(-MovementInput.X, Settings.VerticalSpeedAccelerationDuration, DeltaTime);
				if(Math::IsNearlyZero(AcceleratedVerticalInput.Value, 0.01))
					AcceleratedVerticalInput.SnapTo(0.0);

				float SegmentLength = VineComp.CurrentVine.CableComp.CableLength / VineComp.CurrentVine.CableComp.NumSegments;
				float AlphaSpeed = Settings.VerticalSpeed / SegmentLength;

				PoleClimbComp.AnimData.PoleClimbVerticalVelocity = Settings.VerticalSpeed * -AcceleratedVerticalInput.Value;
				PoleClimbComp.AnimData.PoleClimbVerticalInput = -AcceleratedVerticalInput.Value;

				float AlphaToAdd = AcceleratedVerticalInput.Value * AlphaSpeed * DeltaTime;

				AddAlphaToMonkeyPosition(AlphaToAdd);

				CurrentLocation = Math::VInterpTo(CurrentLocation, MonkeyAttachPoint, DeltaTime, Settings.VelocityInterpSpeed);
				Movement.AddDelta(CurrentLocation - Player.ActorLocation);
				// Player.Mesh.WorldRotation = FRotator::MakeFromZX(MonkeyAttachUpVector, Player.ActorForwardVector);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"PoleClimb");

			//Debug::DrawDebugSphere(VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex1].Position, 50.0, 12, FLinearColor::Red);
			// Debug::DrawDebugSphere(MonkeyAttachPoint, 50.0, 12, FLinearColor::Red, 10.0);
			//MoveComp.ApplyMove(Movement);

			// UpdateFixedParticles();

		}
	}

	void UpdateFixedParticles()
	{
		// VineComp.ResetFixedParticles();
		// VineComp.SetFixedParticleClamped(VineComp.MonkeyAttachParticleIndex1 - 1);
		// VineComp.SetFixedParticleClamped(VineComp.MonkeyAttachParticleIndex2 + 1);
		// VineComp.SetPositionOfFixedParticle(0, SnowMonkeyComp.GetShapeMesh().GetSocketLocation(n"RightHand"));
		// VineComp.SetPositionOfFixedParticle(0, SnowMonkeyComp.GetShapeMesh().GetSocketLocation(n"RightFoot"));
		
		////////////
		////////////
		////////////

		const FVector RightHand = SnowMonkeyComp.GetShapeMesh().GetSocketLocation(n"RightHand");
		const FVector RightFoot = SnowMonkeyComp.GetShapeMesh().GetSocketLocation(n"RightFoot");

		// add some force towards the animated hands and feet
		const float ForceStr = 50000.0;
		const float ForceFalloffExp = 0.5;
		const float DistThreshold = 120.0;
		const float DistSQThreshold = Math::Square(DistThreshold);
		if(VineComp.CurrentVine != nullptr)
		{
			auto& Particles = VineComp.CurrentVine.CableComp.Particles;
			for(auto& P : Particles)
			{
				// HAND
				const FVector DeltaToHand = (RightHand - P.Position);
				const float DistToHandSQ = DeltaToHand.SizeSquared(); 
				if(DistToHandSQ <  DistSQThreshold)
				{
					const float DistToHand = Math::Max(Math::Sqrt(DistToHandSQ), KINDA_SMALL_NUMBER);
					const float Alpha = Math::Pow(1.0 - Math::Saturate(DistToHand / DistThreshold), ForceFalloffExp);
					P.Force += DeltaToHand.GetSafeNormal() * Alpha * ForceStr;
					Debug::DrawDebugSphere(P.Position, DistThreshold);
					PrintToScreen("adding force to Hand" + Alpha);
				}

				// FOOT
				const FVector DeltaToFoot = (RightFoot - P.Position);
				const float DistToFootSQ = DeltaToFoot.SizeSquared(); 
				if(DistToFootSQ <  DistSQThreshold)
				{
					const float DistToFoot = Math::Max(Math::Sqrt(DistToFootSQ), KINDA_SMALL_NUMBER);
					const float Alpha = Math::Pow(1.0 - Math::Saturate(DistToFoot / DistThreshold), ForceFalloffExp);
					P.Force += DeltaToFoot.GetSafeNormal() * Alpha * ForceStr;
				}
			}
		}

		// Debug forces
		auto& Particles = VineComp.CurrentVine.CableComp.Particles;
		for(auto& P : Particles)
		{
			if(P.Force.Size() > 0.0)
			{
				PrintToScreen("P force Size: " + P.Force.Size());
				Debug::DrawDebugArrow(
					P.Position,
					P.Position + P.Force.GetSafeNormal() * 500.0,
					500.0,
					FLinearColor::MakeFromHSV8(uint8(P.Force.Size() % 255), 128, 255),
					10
				);
			}
		}

	}

	void AddAlphaToMonkeyPosition(float AlphaToAdd)
	{
		VineComp.MonkeyAttachParticleAlpha += AlphaToAdd;
		WrapAndClampAlpha();
	}

	void WrapAndClampAlpha()
	{
		float TotalCableLength = VineComp.CurrentVine.CableComp.CableLength;
		float SegmentLength = TotalCableLength / VineComp.CurrentVine.CableComp.NumSegments;
		float CurrentLength = VineComp.MonkeyAttachParticleIndex1 * SegmentLength + SegmentLength * VineComp.MonkeyAttachParticleAlpha;
		CurrentLength = Math::Clamp(CurrentLength, Settings.UpperVinePadding, TotalCableLength - Settings.LowerVinePadding);

		VineComp.MonkeyAttachParticleIndex1 = Math::FloorToInt(CurrentLength / SegmentLength);
		VineComp.MonkeyAttachParticleIndex2 = VineComp.MonkeyAttachParticleIndex1 + 1;
		VineComp.MonkeyAttachParticleAlpha = Math::Fmod(CurrentLength, SegmentLength) / SegmentLength;
	}

	FVector GetMonkeyAttachPoint() property
	{
		FVector ParticlePos1 = VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex1].Position;
		FVector ParticlePos2 = VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex2].Position;
		AccParticle1.AccelerateTo(ParticlePos1, 0.5, Time::GetActorDeltaSeconds(VineComp.CurrentVine));
		AccParticle2.AccelerateTo(ParticlePos2, 0.5, Time::GetActorDeltaSeconds(VineComp.CurrentVine));

		return Math::Lerp(AccParticle1.Value, AccParticle2.Value, VineComp.MonkeyAttachParticleAlpha) - Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight;
		//return ParticlePos1 - Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight;
	}

	FVector GetMonkeyAttachUpVector() const property
	{
		FVector ParticlePos1 = VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex1].Position;
		FVector ParticlePos2 = VineComp.CurrentVine.CableComp.Particles[VineComp.MonkeyAttachParticleIndex2].Position;

		return (ParticlePos1 - ParticlePos2).GetSafeNormal();
	}
}

struct FTundraPlayerSnowMonkeyClimbableVineMovementDeactivatedParams
{
	bool bPressedJump;
}