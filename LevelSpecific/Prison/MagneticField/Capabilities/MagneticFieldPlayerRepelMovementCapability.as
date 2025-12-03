class UMagneticFieldPlayerRepelMovementCapability : UHazeCapability
{
	const bool DEBUG_DRAW = false;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityTags.Add(PrisonTags::ExoSuit);
	default CapabilityTags.Add(ExoSuitTags::MagneticField);
	default CapabilityTags.Add(n"MagneticFieldRepel");
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	USteppingMovementData MoveData;

	UMagneticFieldPlayerComponent PlayerComp;

	FVector MovementForce;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);

		PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!PlayerComp.GetIsMagnetActive())
			return false;

		if (!PlayerComp.IsInMagneticZone())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!PlayerComp.GetIsMagnetActive())
			return true;

		if (!PlayerComp.IsInMagneticZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementForce = MoveComp.MovementInput * MagneticField::RepelHorizontalMovementMultiplier;

		if(PlayerComp.CurrentHoverVolume != nullptr && PlayerComp.CurrentHoverVolume.bLimitFallVelocity)
		{
			// We are between to magnetic fields, and probably don't want to fall down between them
			FVector VerticalVelocity = MoveComp.Velocity.ProjectOnToNormal(FVector::UpVector);

			// Remove vertical velocity if we are falling
			if(VerticalVelocity.Z < 0)
			{
				FVector HorizontalVelocity = Player.GetActorVelocity() - VerticalVelocity;
				VerticalVelocity *= PlayerComp.CurrentHoverVolume.FallVelocityKeptFraction;
				Player.SetActorVelocity(HorizontalVelocity + VerticalVelocity);
			}
		}

		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			FVector AccumulatedRepelForce = FVector::ZeroVector;
			FVector HorizontalNormal = FVector::ZeroVector;
			AccumulateMagneticFields(AccumulatedRepelForce, HorizontalNormal);
			AccumulatedRepelForce *= DeltaTime;

			// Get the velocity from the last frame, which we will apply the forces to
			FVector Velocity = MoveComp.GetVelocity();

			// Add accumulated force from all magnetic fields
			Velocity += AccumulatedRepelForce;

			// Add horizontal input movement
			{
				FVector DesiredMovementForce = MoveComp.MovementInput * MagneticField::RepelHorizontalMovementMultiplier;
				MovementForce = Math::VInterpTo(MovementForce, DesiredMovementForce, DeltaTime, MagneticField::RepelHorizontalMovementInterpSpeed);
				
				Velocity += MovementForce.VectorPlaneProject(HorizontalNormal) * DeltaTime;
			}

			// Add drag
			{
				const float IntegratedVerticalDragFactor = Math::Exp(-MagneticField::RepelVerticalDrag);
				const FVector NewVerticalVelocity = MoveComp.VerticalVelocity * Math::Pow(IntegratedVerticalDragFactor, DeltaTime);
				const FVector VerticalDrag = NewVerticalVelocity - MoveComp.VerticalVelocity;

				const float IntegratedHorizontalDragFactor = Math::Exp(-MagneticField::RepelHorizontalDrag);
				const FVector NewHorizontalVelocity = MoveComp.HorizontalVelocity * Math::Pow(IntegratedHorizontalDragFactor, DeltaTime);
				FVector HorizontalDrag = NewHorizontalVelocity - MoveComp.HorizontalVelocity;

				// Hover volume can add some extra dampening to prevent ping ponging
				if(PlayerComp.CurrentHoverVolume != nullptr && PlayerComp.CurrentHoverVolume.bDampenSideVelocity)
				{
					FVector SideDirection = PlayerComp.CurrentHoverVolume.GetSideVector();
					FVector SideVelocity = MoveComp.HorizontalVelocity.ProjectOnToNormal(SideDirection);
					const float IntegratedSideDampenFactor = Math::Exp(-PlayerComp.CurrentHoverVolume.DampenSideVelocityForce);
					const FVector NewSideVelocity = SideVelocity * Math::Pow(IntegratedSideDampenFactor, DeltaTime);
					HorizontalDrag += NewSideVelocity - SideVelocity;
				}

				FVector Drag = VerticalDrag + HorizontalDrag;
				Drag = Drag.GetClampedToMaxSize(MoveComp.Velocity.Size());

				Velocity += Drag;	// Add this before gravity as to not interfere
			}

			// Finish MoveData and apply
			MoveData.AddGravityAcceleration();
			MoveData.AddVelocity(Velocity);

			// Face velocity direction
			MoveData.InterpRotationToTargetFacingRotation(AirMotionComp.Settings.MaximumTurnRate * MoveComp.MovementInput.Size());
		}
		else // !HasControl
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		// Make sure to stay airborne
		MoveData.RequestFallingForThisFrame();

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, n"AirMovement");
	}

	void AccumulateMagneticFields(FVector& AccumulatedRepelForce, FVector& HorizontalNormal) const
	{
		const FVector ForceOrigin = PlayerComp.GetMagneticFieldCenterPoint();
		for(const auto& Overlap : PlayerComp.QueryNearbyOverlaps(ForceOrigin))
		{
			// Get all magnetic fields from the nearby overlaps
			TArray<UMagneticFieldRepelComponent> MagneticFields;
			Overlap.Actor.GetComponentsByClass(MagneticFields);

			const FVector PlayerLocation = Player.GetActorCenterLocation();

			// Accumulate the repel force from all magnetic zones
			for(auto& MagneticField : MagneticFields)
			{
				// Check if we are in a magnetic zone, and if so, how far from the base
				float VerticalDist = 0.0;
				if(!MagneticField.IsPointInsideZone(PlayerLocation, false, VerticalDist))
					continue;

				// Get the margin alpha, returns 1 if margin is disabled
				float MarginAlpha = MagneticField.GetInsideZoneGradientAlpha(PlayerLocation);
				if(MarginAlpha < KINDA_SMALL_NUMBER)
					continue;

				// If we are not launching, add the force
				// Scale the velocity based on distance from the surface.
				FVector RepelForce = MagneticField.GetRepelForce(VerticalDist) * MarginAlpha;

				if(DEBUG_DRAW)
					Debug::DrawDebugDirectionArrow(Player.ActorLocation, RepelForce.GetSafeNormal(), RepelForce.Size(), 10.0, FLinearColor::Green, 5.0, 5.0);

				AccumulatedRepelForce += RepelForce;

				// Accumulate the normals of all magnetic fields
				HorizontalNormal += MagneticField.UpVector;
			}
		}

		// Normalize, this should average out all of the normals.
		if(!HorizontalNormal.IsZero())
			HorizontalNormal = HorizontalNormal.GetSafeNormal();
		else
			HorizontalNormal = MoveComp.WorldUp;
	}
}