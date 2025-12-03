class UIslandDroidZiplinePlayerEnterHangCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"DroidZipline");

	default BlockExclusionTags.Add(n"DroidZipline");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTargetablesComponent TargetablesComponent;
	UIslandDroidZiplinePlayerComponent DroidZiplineComp;
	UPlayerGrappleComponent GrappleComp;
	UIslandDroidZiplinePlayerSettings Settings;
	UTeleportingMovementData Movement;
	UPlayerMovementComponent MoveComp;
	FVector TargetLocation;
	FVector StartLocation;
	bool bMoveDone = false;
	bool bMoving = false;
	float TimeOfStartMoving;
	FQuat TargetRotation;
	FVector2D OriginalCapsuleSize;
	FTransform ExpectedDroidTransform;
	FVector DroidVelocity;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && !IsBlocked() && DroidZiplineComp.CurrentTargetable == nullptr)
		{
			TargetablesComponent.ShowWidgetsForTargetables(ActionNames::Interaction);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		DroidZiplineComp = UIslandDroidZiplinePlayerComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		Settings = UIslandDroidZiplinePlayerSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		OriginalCapsuleSize = FVector2D(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(DroidZiplineComp.CurrentDroidZipline == nullptr)
			return false;

		if(DroidZiplineComp.bAttached)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroidZiplineComp.CurrentTargetable.Disable(DroidZiplineComp);
		
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, DroidZiplineComp);
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandTargeting, DroidZiplineComp);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, DroidZiplineComp);
		Player.BlockCapabilities(n"Knockdown", DroidZiplineComp);
		Player.BlockCapabilities(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade, DroidZiplineComp);
		Player.BlockCapabilities(CapabilityTags::Death, DroidZiplineComp);
		Droid.SidewaysDistance.OverrideControlSide(Player);
		Droid.CurrentTiltValue.OverrideControlSide(Player);
		Droid.BlockCapabilities(CapabilityTags::Movement, DroidZiplineComp);

		ExpectedDroidTransform = DroidZiplineComp.ExpectedDroidTransform;
		DroidVelocity = (ExpectedDroidTransform.Location - Droid.ActorLocation) / TotalEnterDuration;

		FVector CapsuleOffset = -Droid.ActorUpVector * (OriginalCapsuleSize.Y * 2.0) + Settings.CapsuleRelativeOffset;
		TargetLocation = ExpectedDroidTransform.Location + CapsuleOffset;
		TargetRotation = ExpectedDroidTransform.Rotation;
		StartLocation = Player.ActorLocation;

		DroidZiplineComp.AnimData.HorizontalDistanceToDroid = StartLocation.DistXY(TargetLocation);
		DroidZiplineComp.AnimData.VerticalDistanceToDroid = Math::Abs(StartLocation.Z - TargetLocation.Z);
		bMoveDone = false;
		bMoving = false;

		// Start Grapple
		GrappleComp.Grapple.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		GrappleComp.Grapple.SetActorHiddenInGame(false);
		GrappleComp.Grapple.Tense = 1.35;
		GrappleComp.Grapple.SetActorRotation((Droid.ActorLocation - GrappleComp.Grapple.ActorLocation).Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DroidZiplineComp.bAttached = true;
		Droid.AttachedPlayer = Player;
		Player.ActorLocation = Droid.ActorLocation - Droid.ActorUpVector * (Player.CapsuleComponent.CapsuleHalfHeight * 2.0) + Settings.CapsuleRelativeOffset;

		// End Grapple
		GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		GrappleComp.Grapple.SetActorHiddenInGame(true);

		FIslandDroidZiplineOnAttachParams Params;
		Params.Player = Player;
		UIslandDroidZiplineEffectHandler::Trigger_OnPlayerAttach(Droid, Params);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = ActiveDuration / TotalEnterDuration;
				Alpha = Math::Saturate(Alpha);

				// We use velocity instead of lerp here because we don't want the movement in the frame where the alpha reaches 1 to be smaller than any other frames.
				Droid.ActorLocation += DroidVelocity * DeltaTime;
				Droid.ActorRotation = Math::LerpShortestPath(Droid.ActorRotation, ExpectedDroidTransform.Rotation.Rotator(), Alpha);

				float GrappleAlpha;
				SetGrappleHookLocation(GrappleAlpha);
				if(!bMoving && GrappleAlpha == 1.0)
				{
					bMoving = true;
					TimeOfStartMoving = Time::GetGameTimeSeconds();
					Player.PlayForceFeedback(DroidZiplineComp.AttachFF, false, false, this);
				}

				if(bMoving)
				{
					Alpha = Time::GetGameTimeSince(TimeOfStartMoving) / Settings.JumpToDroidDuration;
					if(Alpha >= 1.0)
					{
						Alpha = 1.0;
						bMoveDone = true;
						Movement.SetRotation(TargetRotation);
					}

					FVector NewLocation = Math::Lerp(StartLocation, TargetLocation, Alpha);
					Movement.AddDelta(NewLocation - Player.ActorLocation);
					Movement.SetRotation(FQuat::Slerp(Player.ActorQuat, TargetRotation, Alpha));
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"DroneHang");
		}
	}

	AIslandDroidZipline GetDroid() property
	{
		return DroidZiplineComp.CurrentDroidZipline;
	}

	float GetTotalEnterDuration() const property
	{
		return Settings.JumpToDroidDuration + Settings.ThrowGrappleDuration;
	}

	void SetGrappleHookLocation(float&out Alpha)
	{
		Alpha = ActiveDuration / Settings.ThrowGrappleDuration;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		FVector RopeLocation = Math::Lerp(Player.Mesh.GetSocketLocation(n"LeftAttach"), Droid.ActorLocation, Alpha);
		GrappleComp.Grapple.SetActorLocation(RopeLocation);
		float NewTense = Math::Lerp(0.6, 0.25, Alpha);
		GrappleComp.Grapple.Tense = NewTense;
	}
}