
class UTundraPlayerTreeGuardianRangedGrappleEnterCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 75;

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionInteraction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UTundraPlayerTreeGuardianSettings Settings;
	UPlayerAimingComponent AimComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	bool bStartedGrounded = false;
	bool bMoveDone = false;
	bool bStartedGrowingRoots = false;
	bool bStartedMoving = false;
	bool bRootsAttached = false;
	float RootsGrowDuration;
	FVector OmniDirectionalNormal;
	USceneComponent RootsOriginPoint;
	UTundraTreeGuardianRangedInteractionTargetableComponent GrappleTargetable;
	UTundraTreeGuardianRangedInteractionTargetableComponent PreviousGrapplePoint;
	UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget CrosshairWidget;
	
	UForceFeedbackEffect EnterForceFeedbackToUse;
	float GrappleForceFeedbackForce;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(ShapeshiftingComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
		{
			// if(Player.IsCapabilityTagBlocked(TundraShapeshiftingTags::ShapeshiftingInput))
			// 	return false;

			return false;
		}

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable == nullptr)
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.IsDisabledForPlayer(Player))
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.InteractionType != ETundraTreeGuardianRangedInteractionType::Grapple)
			return false;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerTreeGuardianRangedGrappleEnterDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
		{
			Params.bShouldEnterGrapple = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);

		CrosshairWidget = TreeGuardianComp.TargetedRangedInteractionCrosshair;
		if(CrosshairWidget != nullptr)
			CrosshairWidget.OnInteractStart(ETundraTreeGuardianRangedInteractionType::Grapple, TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable);

		bStartedGrounded = MoveComp.HasGroundContact();
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		bStartedGrowingRoots = false;
		bMoveDone = false;
		bStartedMoving = false;
		bRootsAttached = false;
		GrappleForceFeedbackForce = 0.0;

		TreeGuardianComp.bCameFromGrapple = TreeGuardianComp.CurrentRangedGrapplePoint != nullptr;
		PreviousGrapplePoint = TreeGuardianComp.CurrentRangedGrapplePoint;

		TreeGuardianComp.GrappleAnimData.bRootsAttached = false;

		GrappleTargetable = TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable;
		OmniDirectionalNormal = (Player.ActorLocation - GrappleTargetable.WorldLocation).GetSafeNormal2D();

		// temp: figure out which hand to grapple with by checking distance for now
		RootsOriginPoint = TreeGuardianComp.TreeGuardianActor.GrappleRightRootsOrigin;
		if(TreeGuardianComp.bCameFromGrapple)
		{
			auto RightGrapple = TreeGuardianComp.TreeGuardianActor.GrappleRightRootsOrigin;
			auto LeftGrapple = TreeGuardianComp.TreeGuardianActor.GrappleLeftRootsOrigin;
			const float RightHandDistanceToTarget = (GrappleTargetable.GetWorldLocation() - RightGrapple.GetWorldLocation()).SizeSquared();
			const float LeftHandDistanceToTarget = (GrappleTargetable.GetWorldLocation() - LeftGrapple.GetWorldLocation()).SizeSquared();
			RootsOriginPoint = RightHandDistanceToTarget < LeftHandDistanceToTarget ? RightGrapple : LeftGrapple;

			EnterForceFeedbackToUse = RightHandDistanceToTarget < LeftHandDistanceToTarget ? TreeGuardianComp.GrappleStartRightFF : TreeGuardianComp.GrappleStartLeftFF;
		}
		else
		{
			EnterForceFeedbackToUse = TreeGuardianComp.GrappleStartRightFF;
		}

		Timer::SetTimer(this, n"EnterForceFeedback", 0.3);
		// RootsOriginPoint = TreeGuardianComp.bCameFromGrapple ? TreeGuardianComp.TreeGuardianActor.GrappleLeftRootsOrigin : TreeGuardianComp.TreeGuardianActor.GrappleRightRootsOrigin;

		RootsGrowDuration = (GrappleTargetable.WorldLocation - RootsOriginPoint.WorldLocation).Size() / Settings.GrappleRootsGrowSpeed;

		GrappleTargetable.CommitInteract();

		FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params;
		Params.RootsOriginPoint = RootsOriginPoint;
		Params.RootsTargetPoint = GrappleTargetable;
		float TelegraphDelay = TreeGuardianComp.bCameFromGrapple 
							 ? Treeguardian::Grapple::AnimationDelays::GrowingRootsWhenAttached 
							 : Treeguardian::Grapple::AnimationDelays::GrowingRoots;
		Params.GrappleDuration = TelegraphDelay;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedGrappleInit(TreeGuardianComp.TreeGuardianActor, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerTreeGuardianRangedGrappleEnterDeactivatedParams Params)
	{
		UCameraSettings::GetSettings(Player).FOV.Clear(n"RangedGrappleEnter", 0.5);
		SpeedEffect::ClearSpeedEffect(Player, this);

		if(!Params.bShouldEnterGrapple)
		{
			Reset();
			return;
		}

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedGrappleReachedPoint(TreeGuardianComp.TreeGuardianActor);

		if(TreeGuardianComp.GrappleAnimData.bAboutToKickback)
			TreeGuardianComp.bInKickback = true;

		TreeGuardianComp.GrappleAnimData.bAboutToReachGrapple = false;
		TreeGuardianComp.GrappleAnimData.bAboutToKickback = false;

		if(GrappleTargetable.bStayAtGrapplePointWhenReaching)
		{
			TreeGuardianComp.CurrentRangedGrapplePoint = GrappleTargetable;
		}
		else
		{
			GrappleTargetable.StartInteract();
			GrappleTargetable.StopInteract();

			if(GrappleTargetable.bApplyImpulseWhenReaching)
			{
				FVector WorldImpulse = Player.ActorTransform.TransformVectorNoScale(GrappleTargetable.LocalPlayerImpulseToApplyWhenReaching);
				if(GrappleTargetable.bCounterPlayersCurrentVelocityWhenApplyingImpulse)
					WorldImpulse -= MoveComp.Velocity;

				MoveComp.AddPendingImpulse(WorldImpulse);
			}
		}
	}

	void Reset()
	{
		UCameraSettings::GetSettings(Player).WorldPivotOffset.Clear(n"RangedGrapple", 0.5);
		GrappleTargetable.StopInteract();
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedGrappleBlocked(TreeGuardianComp.TreeGuardianActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				const FVector RemainingTotalDelta = (Destination - Player.ActorLocation);
				float RemainingDistance = RemainingTotalDelta.Size();
				FVector Direction = RemainingTotalDelta.GetSafeNormal();

				if(ShouldStartMoving(DeltaTime))
				{
					float CurrentDelta = Settings.GrappleEnterSpeed * DeltaTime;
					if(CurrentDelta > RemainingDistance)
					{
						bMoveDone = true;
						CurrentDelta = RemainingDistance;
					}

					RemainingDistance -= CurrentDelta;

					if(RemainingDistance <= Settings.DistanceFromGrapplePointToStartPreparingToAttach)
					{
						CrumbOnStartPreparingToAttach();
					}

					Movement.AddDeltaWithCustomVelocity(Direction * CurrentDelta, Direction * Settings.GrappleEnterSpeed);

					// We want the force feedback to stop a bit before hitting the grapple point, so that the burst that plays when hitting the grapple point has a better impact.
					if(RemainingDistance > 200)
					{
						GrappleForceFeedbackForce += DeltaTime;
						GrappleForceFeedbackForce = Math::Min(GrappleForceFeedbackForce, 0.5);
						Player.SetFrameForceFeedback(GrappleForceFeedbackForce, GrappleForceFeedbackForce, 0.0, 0.0);
					}
				}

				HandleRotation(DeltaTime, RemainingDistance, Direction);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName Tag = TreeGuardianComp.bCameFromGrapple ? n"TreeGuardianGrappleFromGrapple" : n"TreeGuardianGrapple";
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, Tag);
		}
	}

	float TravelDuration = 0.0;

	// Handles anticipation delays for animation, roots growing etc, also rotation.
	bool ShouldStartMoving(float DeltaTime)
	{
		float RelevantDelayBefoeStartGrowing = TreeGuardianComp.bCameFromGrapple 
											 ? Treeguardian::Grapple::AnimationDelays::GrowingRootsWhenAttached 
											 : Treeguardian::Grapple::AnimationDelays::GrowingRoots;

		if(ActiveDuration < RelevantDelayBefoeStartGrowing)
			return false;

		TravelDuration = (Destination - Player.ActorLocation).Size() / Settings.GrappleEnterSpeed;

		if(!bStartedGrowingRoots)
		{
			CrumbStartGrowingRoots();
			bStartedGrowingRoots = true;
		}

		// DrawTempRoots(DeltaTime);

		if((ActiveDuration - RelevantDelayBefoeStartGrowing) < RootsGrowDuration)
			return false;

		if(!bRootsAttached)
		{
			CrumbOnRootsAttached();
			Player.PlayForceFeedback(TreeGuardianComp.GrappleRootsAttachFF, false, true, this);
			bRootsAttached = true;
		}

		float RelevantDelayBeforeStartMoving = TreeGuardianComp.bCameFromGrapple 
											 ? Treeguardian::Grapple::AnimationDelays::MovingAfterGrowingRootsWhenAttached 
											 : Treeguardian::Grapple::AnimationDelays::MovingAfterGrowingRoots;

		if((ActiveDuration - RelevantDelayBefoeStartGrowing - RootsGrowDuration) < RelevantDelayBeforeStartMoving)
			return false;

		if(!bStartedMoving)
		{
			if(TreeGuardianComp.bCameFromGrapple)
				CrumbLeaveGrapplePoint(PreviousGrapplePoint);

			// const float GrappleDuration = (Destination - Player.ActorLocation).Size() / Settings.GrappleEnterSpeed;
			const float GrappleDuration = TravelDuration;

			UCameraSettings CamSettings = UCameraSettings::GetSettings(Player);
			CamSettings.FOV.Apply(CamSettings.FOV.Value * 1.3, n"RangedGrappleEnter", GrappleDuration);
			SpeedEffect::RequestSpeedEffect(Player, Settings.SpeedEffectAmount, this, EInstigatePriority::Normal);

			if(GrappleTargetable.bStayAtGrapplePointWhenReaching)
			{
				FVector WorldOffset = RelevantGrappleNormal * 200.0;
				CamSettings.WorldPivotOffset.Apply(WorldOffset, n"RangedGrapple", GrappleDuration);
			}
			else
			{
				CamSettings.WorldPivotOffset.Clear(n"RangedGrapple", GrappleDuration);
			}

			CrumbOnStartedGrappleEnter(GrappleDuration);
			bStartedMoving = true;
		}

		return true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLeaveGrapplePoint(UTundraTreeGuardianRangedInteractionTargetableComponent Grapple)
	{
		Grapple.LeaveGrapplePoint();
	}

	void HandleRotation(float DeltaTime, float RemainingDistanceAfterMove, FVector MoveDirection)
	{
		if(RemainingDistanceAfterMove < Settings.DistanceFromGrapplePointToStartPreparingToAttach)
		{
			FQuat TargetQuat = FQuat::MakeFromXZ(-RelevantGrappleNormal, GrappleTargetable.UpVector);
			float Alpha = 1.0 - (RemainingDistanceAfterMove / Settings.DistanceFromGrapplePointToStartPreparingToAttach);
			FQuat NewQuat = FQuat::Slerp(Player.ActorQuat, TargetQuat, Alpha);
			Movement.SetRotation(NewQuat);
			return;
		}

		if(!TreeGuardianComp.bCameFromGrapple)
		{
			FQuat TargetRotation;
			if(bStartedGrounded && !bStartedMoving)
			{
				TargetRotation = FQuat::MakeFromZX(FVector::UpVector, MoveDirection);
			}
			else
			{
				TargetRotation = FQuat::MakeFromXZ(MoveDirection, FVector::UpVector);
			}

			Movement.InterpRotationTo(TargetRotation, Settings.TreeGuardianRotationInterpSpeed);
		}
	}

	void DrawTempRoots(float DeltaTime)
	{
		float RelevantDelayBefoeStartGrowing = TreeGuardianComp.bCameFromGrapple 
											 ? Treeguardian::Grapple::AnimationDelays::GrowingRootsWhenAttached 
											 : Treeguardian::Grapple::AnimationDelays::GrowingRoots;

		FVector RootsOrigin = RootsOriginPoint.WorldLocation;
		FVector RootsDestination = GrappleTargetable.WorldLocation;

		float CurrentAlpha = (ActiveDuration - RelevantDelayBefoeStartGrowing) / RootsGrowDuration;
		FVector RootsCurrentEnd = Math::Lerp(RootsOrigin, RootsDestination, Math::Clamp(CurrentAlpha, 0.0, 1.0));

		Debug::DrawDebugLine(RootsOrigin, RootsCurrentEnd, FLinearColor::Green, 15.0);
	}

	FVector GetDestination() property
	{
		FTransform RelevantTransform = GrappleTargetable.WorldTransform;
		if(GrappleTargetable.bOmniDirectionalGrapplePoint)
			RelevantTransform = FTransform(FQuat::MakeFromXZ(RelevantGrappleNormal, GrappleTargetable.UpVector), GrappleTargetable.WorldLocation, GrappleTargetable.WorldScale);

		return GrappleTargetable.WorldLocation + RelevantTransform.TransformVectorNoScale(Settings.GrappleRelativeOffset);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnStartPreparingToAttach()
	{
		if(!GrappleTargetable.bStayAtGrapplePointWhenReaching && GrappleTargetable.bApplyImpulseWhenReaching)
			TreeGuardianComp.GrappleAnimData.bAboutToKickback = true;
		else
			TreeGuardianComp.GrappleAnimData.bAboutToReachGrapple = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnRootsAttached()
	{
		TreeGuardianComp.TriggerRangedInteractionRootsHitSurfaceEffectEvent(GrappleTargetable, ETundraTreeGuardianRangedInteractionType::Grapple);
		TreeGuardianComp.GrappleAnimData.bRootsAttached = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartGrowingRoots()
	{
		FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params;
		Params.GrowTime = RootsGrowDuration;
		Params.TravelTime = TravelDuration;
		Params.InteractionType = ETundraTreeGuardianRangedInteractionType::Grapple;
		Params.RootsOriginPoint = RootsOriginPoint;
		Params.RootsTargetPoint = GrappleTargetable;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnStartGrowingOutRangedInteractionRoots(TreeGuardianComp.TreeGuardianActor, Params);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnStartedGrappleEnter(float GrappleDuration)
	{
		FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params;
		Params.GrappleDuration = GrappleDuration;
		Params.RootsOriginPoint = RootsOriginPoint;
		Params.RootsTargetPoint = GrappleTargetable;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRangedGrappleStartedEnter(TreeGuardianComp.TreeGuardianActor, Params);
	}

	private FVector GetRelevantGrappleNormal() const property
	{
		return GrappleTargetable.bOmniDirectionalGrapplePoint ? OmniDirectionalNormal : GrappleTargetable.ForwardVector;
	}

	UFUNCTION()
	void EnterForceFeedback()
	{
		Player.PlayForceFeedback(EnterForceFeedbackToUse, false, true, this);
	}
}

struct FTundraPlayerTreeGuardianRangedGrappleEnterDeactivatedParams
{
	bool bShouldEnterGrapple = false;
}