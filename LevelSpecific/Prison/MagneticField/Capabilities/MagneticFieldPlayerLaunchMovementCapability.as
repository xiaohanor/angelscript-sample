class UMagneticFieldPlayerLaunchMovementCapability : UHazeCapability
{
	const bool DEBUG_DRAW = false;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityTags.Add(PrisonTags::ExoSuit);
	default CapabilityTags.Add(ExoSuitTags::MagneticField);
	default CapabilityTags.Add(n"MagneticFieldRepel");
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	USteppingMovementData MoveData;

	UMagneticFieldPlayerComponent MagneticFieldPlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);

		MagneticFieldPlayerComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MagneticFieldPlayerComp.GetIsMagnetActive())
			return false;

		const bool bIsBursting = MagneticFieldPlayerComp.GetChargeState() == EMagneticFieldChargeState::Burst || MagneticFieldPlayerComp.HasRecentlyMagnetizeBursted(MagneticField::BurstLaunchBufferTime);
		if(!bIsBursting)
			return false;

		if (!IsInLaunchMagneticField())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MagneticFieldPlayerComp.GetIsMagnetActive())
			return true;

		if (!IsInLaunchMagneticField())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			FVector HorizontalNormal = FVector::ZeroVector;
			FVector LaunchForce = FVector::ZeroVector;

			const FVector ForceOrigin = MagneticFieldPlayerComp.GetMagneticFieldCenterPoint();
			for(const auto& Overlap : MagneticFieldPlayerComp.QueryNearbyOverlaps(ForceOrigin))
			{
				// Get all magnetic fields from the nearby overlaps
				TArray<UMagneticFieldRepelComponent> MagneticFields;
				Overlap.Actor.GetComponentsByClass(MagneticFields);

				const FVector PlayerLocation = Player.GetActorCenterLocation();

				// Accumulate the repel force from all magnetic zones
				for(auto& MagneticField : MagneticFields)
				{
					// Check if we are in a magnetic zone, and if so, how far from the base
					const bool bBurst = (MagneticFieldPlayerComp.GetChargeState() == EMagneticFieldChargeState::Burst) && MagneticField.bLaunchOnBurst;
					float VerticalDist = 0.0;
					if(!MagneticField.IsPointInsideZone(PlayerLocation, bBurst, VerticalDist))
						continue;

					// Get the margin alpha, returns 1 if margin is disabled
					float MarginAlpha = MagneticField.GetInsideZoneGradientAlpha(PlayerLocation);
					if(MarginAlpha < KINDA_SMALL_NUMBER)
						continue;

					if(MagneticFieldPlayerComp.IsLaunchedBy(MagneticField))
					{
						// If we have previously been launched by this magnetic field, keep being launched.
						FVector LaunchImpulse = MagneticField.GetLaunchImpulse() * MarginAlpha;
						LaunchForce += LaunchImpulse;

						if(DEBUG_DRAW)
							Debug::DrawDebugDirectionArrow(Player.ActorLocation, LaunchImpulse.GetSafeNormal(), LaunchImpulse.Size(), 10.0, FLinearColor::Yellow, 5.0, 5.0);
					}
					else if(MagneticField.bLaunchOnBurst && (MagneticFieldPlayerComp.GetChargeState() == EMagneticFieldChargeState::Burst || MagneticFieldPlayerComp.HasRecentlyMagnetizeBursted(MagneticField::BurstLaunchBufferTime)))
					{
						// If the magnetic field allows launching, and we just burst, start being launched
						FVector LaunchImpulse = MagneticField.GetLaunchImpulse() * MarginAlpha;
						LaunchForce += LaunchImpulse;

						CrumbOnPlayerLaunched(MagneticField);

#if EDITOR
						if(DEBUG_DRAW)
							Debug::DrawDebugDirectionArrow(Player.ActorLocation, LaunchImpulse.GetSafeNormal(), LaunchImpulse.Size(), 10.0, FLinearColor::Red, 5.0, 5.0);
#endif
					}

					// Accumulate the normals of all magnetic fields
					HorizontalNormal += MagneticField.UpVector;
				}
			}

			// Normalize, this should average out all of the normals.
			if(!HorizontalNormal.IsZero())
				HorizontalNormal = HorizontalNormal.GetSafeNormal();
			else
				HorizontalNormal = MoveComp.WorldUp;

			// The player is being launched, simplify the velocity to make it more consistent. Input, drag and forces can introduce inconsistency.
			const FVector Velocity = LaunchForce;

			// Finish MoveData and apply
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

	bool IsInLaunchMagneticField() const
	{
		const FVector PlayerLocation = Player.GetActorCenterLocation();

		bool bIsInsideLaunchedBy = false;

		const FVector ForceOrigin = MagneticFieldPlayerComp.GetMagneticFieldCenterPoint();
		for (const auto& Overlap : MagneticFieldPlayerComp.QueryNearbyOverlaps(ForceOrigin))
		{
			auto MagneticField = UMagneticFieldRepelComponent::Get(Overlap.Actor);
			if(MagneticField == nullptr)
				continue;

			if(MagneticField.bLaunchOnBurst)
			{
				float VerticalDist;
				if (MagneticField.IsPointInsideZone(PlayerLocation, true, VerticalDist))
				{
					bIsInsideLaunchedBy = true;
					continue;
				}
			}
			else
			{
				if(!MagneticFieldPlayerComp.IsLaunchedBy(MagneticField))
				{
					// If we are inside of a magnetic field that is not launching us, we should stop being launched
					float VerticalDist;
					if (MagneticField.IsPointInsideZone(PlayerLocation, false, VerticalDist))
						return false;
				}
			}
		}

		return bIsInsideLaunchedBy;
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnPlayerLaunched(UMagneticFieldRepelComponent MagneticField)
	{
		FMagneticFieldLaunchData LaunchData;
		LaunchData.LaunchedFrom = MagneticField;
		MagneticFieldPlayerComp.LaunchDatas.Add(LaunchData);

		MagneticField.OnPlayerLaunchedEvent.Broadcast(Player);
	}
}