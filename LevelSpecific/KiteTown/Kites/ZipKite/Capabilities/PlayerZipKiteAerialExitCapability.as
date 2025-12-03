struct FPlayerZipKiteAerialExitDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerZipKiteAerialExitCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::ZipKite);

	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::ActionMovement;
	// default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 4, 1);
	// default TickGroupOrder = 5;
	// default TickGroupSubPlacement = 5;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 1;

	AZipKite Kite;
	AZipKiteFocusActor FocusActor;

	UZipKitePlayerComponent ZipKitePlayerComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerMovementComponent MoveComp;
	UPlayerSprintComponent SprintComp;
	USteppingMovementData Movement;

	float EnterTime = 0;

	FVector LocalDirection;
	FVector LocalPosition;
	FVector LocalVelocity;
	FVector TargetLocation;
	FVector LandingPointRelativeInitialPosition;
	USceneComponent LandingTargetComp;

	const float GRAPPLE_REEL_DURATION = 0.09;
	const float GRAPPLE_REEL_DELAY = 0.18;

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		ZipKitePlayerComp = UZipKitePlayerComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerZipKiteActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (ZipKitePlayerComp.CurrentKite == nullptr)
			return false;

		if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::AerialExit)
			return false;
		
		Params.ZipKiteData = ZipKitePlayerComp.PlayerKiteData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerZipKiteAerialExitDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= EnterTime)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerZipKiteActivationParams Params)
	{
		ZipKitePlayerComp.PlayerKiteData = Params.ZipKiteData;
		LandingTargetComp = ZipKitePlayerComp.PlayerKiteData.CurrentKite.PlayerLandingPointComp;

		Kite = ZipKitePlayerComp.PlayerKiteData.CurrentKite;

		//Calculate our trajectory as well as our EnterTime
		FVector WorldUp = MoveComp.WorldUp;
		FVector DeltaToPoint = LandingTargetComp.WorldLocation - Player.ActorLocation;
		FVector HorizontalDelta = DeltaToPoint.ConstrainToPlane(WorldUp);
		float HorizontalDistance = HorizontalDelta.Size();
		FVector DirectionToKite = HorizontalDelta.GetSafeNormal();
		float HorizontalStartSpeed = DirectionToKite.DotProduct(Player.ActorHorizontalVelocity);

		float WantedTime = 0.0;
		if(!DirectionToKite.IsNearlyZero())
			WantedTime = HorizontalDelta.Size() / Math::Max(AirMotionComp.Settings.HorizontalMoveSpeed, HorizontalStartSpeed);
		
		//Clamp our entry time within a reasonable range
		EnterTime = Math::Clamp(WantedTime, 1.25, 1.5);

		FVector ToTargetVertical = DeltaToPoint.ConstrainToPlane(HorizontalDelta.GetSafeNormal());

		//Append some extra airtime if our required vertical is excessive
		EnterTime += Math::GetMappedRangeValueClamped(FVector2D(1000, 3000), FVector2D(0, 1.25), ToTargetVertical.Size());

		float NeededVertical = Trajectory::GetSpeedToReachTarget(DeltaToPoint.DotProduct(WorldUp), EnterTime, -MoveComp.GetGravityForce());

		LocalPosition = Player.ActorLocation - ZipKitePlayerComp.PlayerKiteData.CurrentKite.PlayerLandingPointComp.WorldLocation;
		LocalDirection = DirectionToKite;
		LocalVelocity = (WorldUp * NeededVertical) + DirectionToKite * (HorizontalDistance / EnterTime);

		TargetLocation = ZipKitePlayerComp.PlayerKiteData.CurrentKite.PlayerLandingPointComp.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerZipKiteAerialExitDeactivationParams Params)
	{
		ZipKitePlayerComp.PlayerKiteData.ResetData();
		Player.ClearCameraSettingsByInstigator(ZipKitePlayerComp, 2);

		Player.ResetMovement(true);

		Kite.OnPlayerDetached.Broadcast(Player);
		Kite.OnPlayerLanded.Broadcast(Player);

		UZipKitePlayerEffectEventHandler::Trigger_Landed(Player);
		UKiteTownVOEffectEventHandler::Trigger_ZipLanded(Game::Mio, KiteTown::GetVOEffectEventParams(Player));

		Kite = nullptr;
		GrappleComp.Grapple.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				TargetLocation = ZipKitePlayerComp.PlayerKiteData.CurrentKite.PlayerLandingPointComp.WorldLocation;

				FVector Gravity = MoveComp.GetGravity();
				LocalPosition += LocalVelocity * DeltaTime;

				LocalVelocity += Gravity * DeltaTime;
				LocalPosition += Gravity * DeltaTime * DeltaTime * 0.5;

				FVector NewLoc = TargetLocation + LocalPosition;
				FVector DeltaMove = NewLoc - Player.ActorLocation;

				//Clamp our final move if we overshoot our target location
				if(DeltaMove.Size() > (TargetLocation - Player.ActorLocation).Size())
					DeltaMove = DeltaMove.GetSafeNormal() * (TargetLocation - Player.ActorLocation).Size();

				FQuat TargetRot = FQuat::MakeFromZX(MoveComp.WorldUp, LocalDirection);
				FQuat Rot = Math::QInterpTo(Player.ActorRotation.Quaternion(), TargetRot, DeltaTime, 13.0);

				//Control our customVelocity incase we cancel this move into something else
				FVector CustomVelocity = (DeltaMove / DeltaTime).GetClampedToMaxSize(
					SprintComp.Settings.MaximumSpeed * MoveComp.MovementSpeedMultiplier
				);

				Movement.SetRotation(Rot);
				Movement.AddDeltaWithCustomVelocity(DeltaMove, CustomVelocity);

			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			HandleGrappleRope();
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ZipKites");
		}
	}

	UFUNCTION()
	void HandleGrappleRope()
	{
		float ReelAlpha = Math::Clamp((ActiveDuration - GRAPPLE_REEL_DELAY) / GRAPPLE_REEL_DURATION , 0, 1);
		FVector NewLoc = Math::Lerp(ZipKitePlayerComp.GetRopeAttachLocationAtDistance(ZipKitePlayerComp.CurrentKite.RuntimeSplineRope.Length - ZipKitePlayerComp.PlayerKiteData.CurrentKite.ZipExitDistance), Player.Mesh.GetSocketLocation(n"LeftAttach"), ReelAlpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);

		if(ReelAlpha >= 1)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);
		}
	}
};