struct FPlayerZipKiteActivationParams
{
	UZipKitePointComponent ZipPoint;
	FPlayerGrappleData GrappleData;
	FZipKitePlayerData ZipKiteData;
}

struct FPlayerZipKiteEnterDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerZipKiteEnterCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(KiteTags::Kite);
	default CapabilityTags.Add(KiteTags::ZipKite);

	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	AZipKite Kite;
	UZipKitePlayerComponent ZipKitePlayerComp;
	UZipKitePointComponent ZipComp;

	UGrapplePointBaseComponent TargetedPoint;

	bool bMoveCompleted = false;

	FVector TargetWorldLocation;

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		ZipKitePlayerComp = UZipKitePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerZipKiteActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::KiteTown_ZipPoint)
			return false;
		
		Params.GrappleData = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerZipKiteEnterDeactivationParams& Params) const
	{
		if (ZipKitePlayerComp.CurrentKite == nullptr)
			return true;

		if (bMoveCompleted)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (ZipKitePlayerComp.PlayerKiteData.PlayerState != EZipKitePlayerStates::Enter)
		{
			if(ZipKitePlayerComp.PlayerKiteData.PlayerState == EZipKitePlayerStates::ZipLining)
				Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerZipKiteActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		MoveComp.FollowComponentMovement(TargetedPoint, this);

		if (Params.ZipPoint != nullptr)
			ZipComp = Params.ZipPoint;
		else
			ZipComp = Cast<UZipKitePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		Kite = Cast<AZipKite>(ZipComp.Owner);
		ZipKitePlayerComp.CurrentKite = Kite;
		ZipKitePlayerComp.CurrentMashSpeedMultiplier = 0.0;
		ZipKitePlayerComp.PlayerKiteData.CurrentKite = Kite;

		GrappleComp.Data = Params.GrappleData;
		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPoint;

		ZipKitePlayerComp.PlayerKiteData.PlayerState = EZipKitePlayerStates::Enter;

		TargetedPoint = Cast<UZipKitePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		//Incase enter found any actors to ignore then maintain that throughout this move
		if(GrappleComp.Data.ActorsToIgnore.Num() > 0)
		{
			MoveComp.AddMovementIgnoresActors(this, GrappleComp.Data.ActorsToIgnore);
		}

		TargetWorldLocation = GetRopeAttachLocation() + (GetRopeAttachRotation().ForwardVector * Kite.ZipOffset.X) + (GetRopeAttachRotation().RightVector * Kite.ZipOffset.Y) + (FVector::UpVector * Kite.ZipOffset.Z);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerZipKiteEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		MoveComp.UnFollowComponentMovement(this);

		//Replicating status
		bMoveCompleted = Params.bMoveCompleted;

		if(bMoveCompleted || ZipKitePlayerComp.PlayerKiteData.PlayerState == EZipKitePlayerStates::ZipLining)
		{
			if (IsValid(TargetedPoint))
				TargetedPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, TargetedPoint);
		}
		else
		{
			// Broadcast interrupted event
			if (IsValid(TargetedPoint))
				TargetedPoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, TargetedPoint);

			ZipKitePlayerComp.PlayerKiteData.ResetData();
			
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);
		}

		// We are transitioning to custom swing like capability from here so just reset everytime
		GrappleComp.Data.ResetData();
		GrappleComp.AnimData.ResetData();

		bMoveCompleted = false;

		MoveComp.RemoveMovementIgnoresActor(this);

		// Clear point for targeting by player again
		if (IsValid(TargetedPoint))
			TargetedPoint.ClearPointForPlayer(Player);

		TargetedPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Speed = Math::Lerp(0, GrappleComp.Settings.GrappleToPointTopVelocity, GrappleComp.AccelerationCurve.GetFloatValue(ActiveDuration / GrappleComp.Settings.GrappleToPointAccelerationDuration));

				FVector Direction = TargetWorldLocation - Player.ActorLocation;
				Direction = Direction.GetSafeNormal();

				FVector FrameDeltaMove = Direction * Speed * DeltaTime;

				if(FrameDeltaMove.Size() > (TargetWorldLocation - Player.ActorLocation).Size() || (TargetWorldLocation - Player.ActorLocation).Size() <= 10)
				{
					FrameDeltaMove = (TargetWorldLocation - Player.ActorLocation);
					bMoveCompleted = true;
					GrappleComp.Data.bGrappleToPointFinished = true;
					ZipKitePlayerComp.PlayerKiteData.PlayerState = EZipKitePlayerStates::ZipLining;
				}

				Movement.SetRotation(Player.ActorRotation);
				Movement.AddDeltaWithCustomVelocity(FrameDeltaMove, FrameDeltaMove.GetSafeNormal() * Speed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Grapple");
		}
	}

	FVector GetRopeAttachLocation()
	{
		return Kite.RuntimeSplineRope.GetLocationAtDistance(Kite.ZipPointHeight);
	}

	FRotator GetRopeAttachRotation()
	{
		FRotator RopeAttachRot = Kite.RuntimeSplineRope.GetRotationAtDistance(Kite.ZipPointHeight);
		RopeAttachRot.Roll = 0.0;
		RopeAttachRot.Pitch = 0.0;

		return RopeAttachRot;
	}
};