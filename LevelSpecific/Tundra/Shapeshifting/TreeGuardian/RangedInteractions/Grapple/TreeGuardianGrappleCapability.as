class UTundraPlayerTreeGuardianRangedGrappleCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionInteraction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerAimingComponent AimComp;
	UTundraPlayerTreeGuardianSettings Settings;
	UTundraPlayerFairySettings FairySettings;
	bool bCancelPromptShown = false;
	uint FrameOfExitGrapple;
	bool bHasAppliedMovementInput = false;

	// The player forward vector in the grapple points local space.
	FVector LocalPlayerForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		AimComp = UPlayerAimingComponent::Get(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		FairySettings = UTundraPlayerFairySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianRangedGrappleActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(TreeGuardianComp.CurrentRangedGrapplePoint == nullptr)
		{
			if(TreeGuardianComp.RangedInteractionTargetableToForceEnter == nullptr)
				return false;

			if(TreeGuardianComp.RangedInteractionTargetableToForceEnter.InteractionType != ETundraTreeGuardianRangedInteractionType::Grapple)
				return false;

			Params.Targetable = TreeGuardianComp.RangedInteractionTargetableToForceEnter;
			return true;
		}

		Params.Targetable = TreeGuardianComp.CurrentRangedGrapplePoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerTreeGuardianRangedGrappleDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
		{
			Params.bExitedGrapple = false;
			return true;
		}

		if(TreeGuardianComp.CurrentRangedGrapplePoint.IsDisabled())
			return true;

		if(TreeGuardianComp.CurrentRangedGrapplePoint.bForceExit)
			return true;

		if(!TreeGuardianComp.CurrentRangedGrapplePoint.bBlockCancel && (WasActionStarted(ActionNames::Cancel)))
			return true;

		if(!TreeGuardianComp.CurrentRangedGrapplePoint.bBlockCancel && WasActionStarted(ActionNames::MovementJump))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianRangedGrappleActivatedParams Params)
	{
		TreeGuardianComp.CurrentRangedGrapplePoint = Params.Targetable;
		TreeGuardianComp.RangedInteractionTargetableToForceEnter = nullptr;
		TreeGuardianComp.CurrentRangedGrapplePoint.StartInteract();

		MoveComp.FollowComponentMovement(TreeGuardianComp.CurrentRangedGrapplePoint, this);
		MoveComp.ApplyCrumbSyncedRelativePosition(this, TreeGuardianComp.CurrentRangedGrapplePoint);

		TreeGuardianComp.GrappleAnimData.bAttached = true;

		LocalPlayerForward = TreeGuardianComp.CurrentRangedGrapplePoint.WorldTransform.InverseTransformVectorNoScale(Player.ActorForwardVector);
		ShapeshiftingComp.ApplyShapeshiftingLocationOverride(FOnShapeshiftLocationOverride(this, n"OnShapeshiftLocationOverride"), this, true);

		Player.PlayForceFeedback(TreeGuardianComp.GrappleTreeStuckLandingFF, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerTreeGuardianRangedGrappleDeactivatedParams Params)
	{
		if(bHasAppliedMovementInput)
		{
			Player.ClearMovementInput(this);
			bHasAppliedMovementInput = false;
		}

		if(Params.bExitedGrapple)
		{
			UCameraSettings::GetSettings(Player).WorldPivotOffset.Clear(n"RangedGrapple", 1.0);
			auto CrosshairWidget = TreeGuardianComp.TargetedRangedInteractionCrosshair;
			if(CrosshairWidget != nullptr)
				CrosshairWidget.OnInteractStop(ETundraTreeGuardianRangedInteractionType::Grapple, TreeGuardianComp.CurrentRangedGrapplePoint);
		}

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		TryClearPrompts();
		
		TreeGuardianComp.CurrentRangedGrapplePoint.StopInteract();

		FrameOfExitGrapple = Time::FrameNumber;

		// If we exited grapple (as opposed to entering a new grapple) we want to call this event now, otherwise the grapple enter capability will call it when it starts moving
		if(Params.bExitedGrapple)
			TreeGuardianComp.CurrentRangedGrapplePoint.LeaveGrapplePoint();

		TreeGuardianComp.CurrentRangedGrapplePoint = nullptr;

		TreeGuardianComp.GrappleAnimData.bAttached = false;

		if(Params.bExitedGrapple)
		{
			UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedGrappleBlocked(TreeGuardianComp.TreeGuardianActor);
		}

		// We don't want to do this because this capability might exit just before the shapeshift actually happens (the same frame).
		//ShapeshiftingComp.ClearShapeshiftingLocationOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleUpdatePrompts();

		if(AimComp.HasAiming2DConstraint())
		{
			Player.ApplyMovementInput(-Player.ActorForwardVector, this, EInstigatePriority::Interaction);
			bHasAppliedMovementInput = true;
		}
		else if(bHasAppliedMovementInput)
		{
			Player.ClearMovementInput(this);
			bHasAppliedMovementInput = false;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			SetAimingDirectionAnimData();
			
			if(HasControl())
			{
				Movement.AddDelta(Destination - Player.ActorLocation);
				auto Rotation = FRotator::MakeFromXZ(-GrappleNormal, TreeGuardianComp.CurrentRangedGrapplePoint.UpVector);
				Movement.SetRotation(Rotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"TreeGuardianGrappleFromGrapple");
		}
	}

	UFUNCTION()
	private bool OnShapeshiftLocationOverride(AHazePlayerCharacter In_Player, ETundraShapeshiftShape FromShape, ETundraShapeshiftShape ToShape, FVector& OutLocationOffset)
	{
		// We weren't in the grapple when we shapeshifted.
		if(!IsActive() && Time::FrameNumber - FrameOfExitGrapple > 1)
			return false;

		devCheck(FromShape == ETundraShapeshiftShape::Big, "How did this even happen?");
		FVector2D FromCapsuleSize = ShapeshiftingComp.GetCapsuleSizeForShape(FromShape);
		FVector2D ToCapsuleSize = ShapeshiftingComp.GetCapsuleSizeForShape(ToShape);

		float HeightToOffset = FromCapsuleSize.Y - ToCapsuleSize.Y;

		OutLocationOffset = FVector::UpVector * HeightToOffset;
		return true;
	}

	void HandleUpdatePrompts()
	{
		if(!ShouldShowPrompts())
		{
			TryClearPrompts();
		}
		else if(!bCancelPromptShown)
		{
			TryClearPrompts();
			if(HasControl())
				CrumbShowCancelPrompt();
		}
	}

	void TryClearPrompts()
	{
		if(!HasControl())
			return;

		if(!IsAnyPromptShown())
			return;

		CrumbClearPrompt();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShowCancelPrompt()
	{
		FTutorialPrompt CancelPrompt;
		CancelPrompt.Action = ActionNames::Cancel;
		CancelPrompt.Text = NSLOCTEXT("Tundra", "TreeGuardianCancelGrapple", "Cancel");

		if(Player.IsPendingFullscreen() || Player.OtherPlayer.IsPendingFullscreen())
			Player.ShowTutorialPromptWorldSpace(CancelPrompt, this, TreeGuardianComp.GetShapeActor().Mesh, FVector(0.0, 0.0, -300.0));
		else
			Player.ShowTutorialPrompt(CancelPrompt, this);
		bCancelPromptShown = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbClearPrompt()
	{
		Player.RemoveTutorialPromptByInstigator(this);
		bCancelPromptShown = false;
	}

	void SetAimingDirectionAnimData()
	{
		if(!AimComp.IsAiming(TreeGuardianComp))
		{
			//TreeGuardianComp.GrappleAnimData.AttachedAimingDirection = FVector2D::ZeroVector;
		}
		else
		{
			FVector Dir = Player.GetViewRotation().ForwardVector;
			FVector LocalPlayerToTarget = Player.ActorTransform.InverseTransformVectorNoScale(Dir);
			FVector RollDirFlat = FVector(0.0, LocalPlayerToTarget.Y, LocalPlayerToTarget.Z).GetSafeNormal();
			FVector2D Result = FVector2D(RollDirFlat.Z, RollDirFlat.Y);

			FVector2D AimAngles = Player.CalculatePlayerAimAngles();
			TreeGuardianComp.GrappleAnimData.AttachedAimingDirection = Result;
			TreeGuardianComp.GrappleAnimData.AttachedAimingYawAngle = AimAngles.X;
			TreeGuardianComp.GrappleAnimData.AttachedAimingRollAngle = AimAngles.Y;
		}
	}

	FVector GetDestination() property
	{
		UTundraTreeGuardianRangedInteractionTargetableComponent Grapple = TreeGuardianComp.CurrentRangedGrapplePoint;
		FVector RelevantGrappleNormal = Grapple.bOmniDirectionalGrapplePoint ? (Player.ActorLocation - Grapple.WorldLocation).GetSafeNormal2D() : Grapple.ForwardVector;

		FTransform RelevantTransform = Grapple.WorldTransform;
		if(Grapple.bOmniDirectionalGrapplePoint)
			RelevantTransform = FTransform(FQuat::MakeFromXZ(RelevantGrappleNormal, TreeGuardianComp.CurrentRangedGrapplePoint.UpVector), Grapple.WorldLocation, Grapple.WorldScale);

		return Grapple.WorldLocation + RelevantTransform.TransformVectorNoScale(Settings.GrappleRelativeOffset);
	}

	private FVector GetGrappleNormal() const property
	{
		return TreeGuardianComp.CurrentRangedGrapplePoint.ForwardVector;
	}

	private bool ShouldShowPrompts() const
	{
		if(TreeGuardianComp.CurrentRangedGrapplePoint.bBlockCancel)
			return false;

		return true;
	}

	private bool IsAnyPromptShown() const
	{
		return bCancelPromptShown;
	}
}

struct FTundraPlayerTreeGuardianRangedGrappleDeactivatedParams
{
	bool bExitedGrapple = true;
}

struct FTundraPlayerTreeGuardianRangedGrappleActivatedParams
{
	UTundraTreeGuardianRangedInteractionTargetableComponent Targetable;
}