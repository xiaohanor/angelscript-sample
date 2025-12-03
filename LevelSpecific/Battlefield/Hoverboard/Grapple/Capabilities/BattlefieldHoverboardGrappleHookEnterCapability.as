
class UBattlefieldHoverboardGrappleHookEnterCapability : UHazePlayerCapability
{
	/*
		- This Capability Slows the player down midair and connects the grapple to target point
		- After this we branch depending on the grappletype to the correct Grapple capability
	*/

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleEnter);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 5;
	default TickGroupSubPlacement = 3;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UBattlefieldHoverboardGrappleComponent GrappleComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UCameraPointOfInterest Poi;

	//Adding the normal player grappleComp for audio purposes
	UPlayerGrappleComponent PlayerGrappleComp;
	UBattlefieldHoverboardGrappleSettings GrappleSettings;

	//Time it takes to complete the enter part of the move, for a quicker grapple, reduce this time
	float Deceleration;

	float Duration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UBattlefieldHoverboardGrappleComponent::GetOrCreate(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		Poi = Player.CreatePointOfInterest();

		PlayerGrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);

		GrappleSettings = UBattlefieldHoverboardGrappleSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGrappleEnterActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!WasActionStarted(ActionNames::Grapple))
			return false;

		if (Player.IsAnyCapabilityActive(PlayerMovementTags::Grapple))
			return false;

		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UGrapplePointBaseComponent);
		if (PrimaryTarget == nullptr)
			return false;
		
		//Verify if we are aiming at a perchpoint and outside of quick grapple range
		if(PrimaryTarget.GrappleType == EGrapplePointVariations::PerchPoint && (Player.ActorLocation - PrimaryTarget.WorldLocation).Size() < PrimaryTarget.ActivationRange)
			return false;

		Params.SelectedGrapplePoint = PrimaryTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGrappleEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= Duration)
		{
			Params.bMoveFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGrappleEnterActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.BlockCapabilities(BlockedWhileIn::GrappleEnter, this);
		
		switch(Params.SelectedGrapplePoint.GrappleType)
		{
			case EGrapplePointVariations::GrapplePoint:
				Duration = GrappleComp.Settings.GrappleEnterDuration;
				break;
			case EGrapplePointVariations::LaunchPoint:
				Duration = GrappleComp.Settings.GrappleLaunchEnterDuration;
				break;
			case EGrapplePointVariations::WallrunPoint:
				Duration = GrappleComp.Settings.GrappleWallrunEnterDuration;
				break;
			default:
				Duration = GrappleComp.Settings.GrappleEnterDuration;
		}

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleEnter;
		PlayerGrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleEnter;

		//Set the current grapple point to be the one that was used to activate this capability
		GrappleComp.Data.CurrentGrapplePoint = Params.SelectedGrapplePoint;
		//Populate Default grapple comp data for audio
		PlayerGrappleComp.Data.CurrentGrapplePoint = Params.SelectedGrapplePoint;

		//Set the point as active for player so its excluded from further targetable polling until we clear
		GrappleComp.Data.CurrentGrapplePoint.ActivateGrapplePointForPlayer(Player);
		PlayerTargetablesComponent.TriggerActivationAnimationForTargetableWidget(Params.SelectedGrapplePoint);

		GrappleComp.AnimData.bInEnter = true;
		
		//If we cancel another grapple into this, we need to detach the grapple actor from whatever it was attached to
		GrappleComp.Grapple.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		//Broadcast initiated event from point
		GrappleComp.Data.CurrentGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);
		

		//During the enter, we want to continue moving with whatever velocity we had initially, and then slightly decelerate
		// FVector EnterVelocity = MoveComp.Velocity;
		// Deceleration = EnterVelocity.Size() / Duration;

		//We unhide the grapple and make it quite loose in the first part of this move by setting a high tense-value
		GrappleComp.Grapple.SetActorHiddenInGame(false);
		GrappleComp.Grapple.Tense = 1.35;
		GrappleComp.Grapple.SetActorRotation((GrappleComp.Data.CurrentGrapplePoint.WorldLocation - GrappleComp.Grapple.ActorLocation).Rotation());

		//Camera stuff
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
			HandleCameraOnActivation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGrappleEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.UnblockCapabilities(BlockedWhileIn::GrappleEnter, this);

		//Upon exiting this move, we check what type the grapplepoint was. This will determine which type of grapple-capability gets activated next, and what animations to play
		if(Params.bMoveFinished)
		{
			HoverboardComp.AnimParams.bIsGrapplingToGrind 
				= GrappleComp.Data.CurrentGrapplePoint.Owner.IsA(ABattlefieldHoverboardGrappleToGrindPoint);

			switch (GrappleComp.Data.CurrentGrapplePoint.GrappleType)
			{
				case(EGrapplePointVariations::LaunchPoint):
					GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleLaunch;
					PlayerGrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleLaunch;
					GrappleComp.AnimData.bLaunching = true;
					break;

				case(EGrapplePointVariations::WallrunPoint):
					GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleWallrun;
					PlayerGrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleWallrun;
					GrappleComp.AnimData.bWallrunGrappling = true;
					break;

				case(EGrapplePointVariations::GrapplePoint):
					GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPoint;
					PlayerGrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPoint;
					GrappleComp.AnimData.bGrappling = true;
					break;

				case(EGrapplePointVariations::SlidePoint):
					GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleSlide;
					GrappleComp.AnimData.bSliding = true;
					break;

				case(EGrapplePointVariations::PerchPoint):
					GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrapplePerch;
					GrappleComp.AnimData.bPerchGrappling = true;
					break;

				case(EGrapplePointVariations::WallScramblePoint):
					GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleWallScramble;
					// GrappleComp.AnimDataGrapple.bWallScrambleGrappling = true;
					GrappleComp.AnimData.bGrappling = true;
					break;

				default:
					GrappleComp.Data.ResetData();
					GrappleComp.AnimData.ResetData();
					PlayerGrappleComp.Data.ResetData();
					break;
			}
		}
		else
		{
			GrappleComp.Data.CurrentGrapplePoint.ClearPointForPlayer(Player);

			//Move didnt finish so cleanup
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
			PlayerGrappleComp.Data.ResetData();

			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

		}

		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 0.25);
		GrappleComp.AnimData.bInEnter = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				//First we decelerate our velocity each frame, going down to 0 felt bad, so we reduce the deceleration amount by dividing it with 1.5
				FVector Velocity = MoveComp.Velocity;
				// Velocity -= Velocity.GetSafeNormal() * (Deceleration / 1.5) * DeltaTime;

				//Then we find out what rotation we want, it should be towards the location of the grapple point we are going towards
				FVector Dir = GrappleComp.Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
				if(Dir.IsNearlyZero())
					Dir = Player.ActorForwardVector;

				FRotator TargetRot = Dir.Rotation();
				FRotator Rot = Math::RInterpTo(Player.ActorRotation, TargetRot, DeltaTime, 6.0);

				FRotator FlatRot = Rot;
				FlatRot.Pitch = 0;
				FlatRot.Roll = 0;
				
				Movement.SetRotation(FlatRot);
				Movement.AddVelocity(Velocity);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"HoverboardGrappling", this);
		}

		//Calculate two alphas, one that goes from 0-1 throught the entire move, and one that does it 66% faster. These values are then used to set the location of the grapple actor, and adjust the tenseness of the rope accordingly
		float VanillaAlpha = ActiveDuration / Duration;
		float Alpha = (ActiveDuration * 1.66) / Duration;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		FVector NewLoc = Math::Lerp(Player.Mesh.GetSocketLocation(n"LeftAttach"), GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Alpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(1.35, 0.55, VanillaAlpha);
		GrappleComp.Grapple.Tense = NewTense;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	void HandleCameraOnActivation()
	{
		Poi.Settings.RegainInputTime = 0;
		Poi.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);
		//Each grapple point has a POI-offset variable that gets added here
		Poi.FocusTarget.LocalOffset = GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset;
		//Calculate vertical offset based on Activation/Minimum Range
		float VerticalOffset = Math::GetMappedRangeValueClamped(FVector2D(GrappleComp.Data.CurrentGrapplePoint.ActivationRange, GrappleComp.Data.CurrentGrapplePoint.MinimumRange), FVector2D(300, 75), GrappleComp.DistToTarget);
		Poi.FocusTarget.WorldOffset = (MoveComp.WorldUp * VerticalOffset);
		//Blend time is longer than the move itself since we don't want to snap the camera in a jerky way
		Poi.Apply(this, 1.85);

		Player.ApplyCameraSettings(GrappleSettings.GrappleEnterCamSetting, 1.85, this, SubPriority = 31);
	}

};

