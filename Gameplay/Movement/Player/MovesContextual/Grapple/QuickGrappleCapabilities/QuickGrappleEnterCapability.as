
class UPlayerQuickGrappleEnterCapability : UHazePlayerCapability
{
	/*
	 * Thoughts:
	 * Should we enforce a minimum range/angle if to close to the grapple point? (Keeping velocity in direction or lerping to a good position)
	 */

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::QuickGrapple);

	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 5;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerPerchComponent PerchComp;

	float MoveDuration = 0.3;
	float Decceleration;

	FVector StartLocation;
	FVector TargetLocation;

	UPerchPointComponent PerchPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FQuickGrappleEnterActivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		if(PerchComp.Data.bPerching || PerchComp.Data.State == EPlayerPerchState::JumpTo)
			return false;

		if(!WasActionStarted(ActionNames::ContextualMovement))
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UGrapplePointBaseComponent);
		if(PrimaryTarget == nullptr)
			return false;

		//TODO(AL): Do we want quick grapple to points other then perch?
		if(PrimaryTarget.GrappleType != EGrapplePointVariations::PerchPoint)
			return false;
		
		//Verify that we are inside the activation / quick grapple range
		if((Player.ActorLocation - PrimaryTarget.WorldLocation).Size() > PrimaryTarget.ActivationRange)
			return false;

		Params.SelectedGrapplePoint = PrimaryTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FQuickGrappleDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		
		if(GrappleComp.Data.GrappleState != EPlayerGrappleStates::QuickGrappleEnter)
			return true;

		if(ActiveDuration >= MoveDuration)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FQuickGrappleEnterActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::ContextualMovement);

		GrappleComp.Data.CurrentGrapplePoint = Params.SelectedGrapplePoint;
		GrappleComp.Data.GrappleState = EPlayerGrappleStates::QuickGrappleEnter;

		GrappleComp.Data.CurrentGrapplePoint.ActivateGrapplePointForPlayer(Player);
		TargetablesComp.TriggerActivationAnimationForTargetableWidget(Params.SelectedGrapplePoint);

		//During the enter, we want to continue moving with whatever velocity we had initially, and then slightly decelerate
		FVector EnterVelocity = MoveComp.Velocity;
		Decceleration = EnterVelocity.Size() / MoveDuration;

		//Broadcast initiatedEvent
		GrappleComp.Data.CurrentGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

		//We unhide the grapple and make it quite loose in the first part of this move by setting a high tense-value
		GrappleComp.Grapple.SetActorHiddenInGame(false);
		GrappleComp.Grapple.Tense = 1.5;
		GrappleComp.Grapple.SetActorRotation((GrappleComp.Data.CurrentGrapplePoint.WorldLocation - GrappleComp.Grapple.ActorLocation).Rotation());

		auto Poi = Player.CreatePointOfInterest();
		Poi.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);
		Poi.FocusTarget.LocalOffset = GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset;
		Poi.FocusTarget.WorldOffset = (MoveComp.WorldUp * 300.0);
		Poi.Apply(this, 1.35);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FQuickGrappleDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		if(Params.bMoveCompleted)
			GrappleComp.Data.GrappleState = EPlayerGrappleStates::QuickGrapplePerch;
		else
		{
			GrappleComp.Data.CurrentGrapplePoint.ClearPointForPlayer(Player);
			GrappleComp.Data.GrappleState = EPlayerGrappleStates::Inactive;
			GrappleComp.Data.ResetData();
		}

		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Velocity = MoveComp.Velocity;
				Velocity -= Velocity.GetSafeNormal() * (Decceleration / 1.75) * DeltaTime;
				// FVector Velocity = MoveComp.Velocity;

				FVector Dir = GrappleComp.Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
				if(Dir.IsNearlyZero())
						Dir = Player.ActorForwardVector;

				FRotator TargetRot = Dir.Rotation();
				FRotator Rot = Math::RInterpTo(Player.ActorRotation, TargetRot, DeltaTime, 6.0);

				Movement.AddVelocity(Velocity);
				Movement.SetRotation(Rot);
				// Movement.AddGravityAcceleration();
			}
			else
				Movement.ApplyCrumbSyncedAirMovement();

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"QuickGrapple");

			float VanillaAlpha = ActiveDuration / MoveDuration;
			float Alpha = (ActiveDuration * 1.66) / MoveDuration;
			Alpha = Math::Clamp(Alpha, 0.0, 1.0);
			FVector NewLoc = Math::Lerp(Player.Mesh.GetSocketLocation(n"LeftAttach"), GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Alpha);
			GrappleComp.Grapple.SetActorLocation(NewLoc);
			float NewTense = Math::Lerp(1.5, 0.55, VanillaAlpha);
			GrappleComp.Grapple.Tense = NewTense;
		}
	}
}

struct FQuickGrappleEnterActivationParams
{
	UGrapplePointBaseComponent SelectedGrapplePoint;
}

struct FQuickGrappleEnterDeactivationParams
{
	bool bMoveCompleted = false;
}