enum ETundraTreeGuardianRangedInteractionType
{
	Grapple,
	LifeGive,
	Shoot,
	IceKingHoldDown,
	MAX UMETA(Hidden)
}

event void FTundraTreeGuardianRangedInteractionEvent();
event void FTundraTreeGuardianRangedInteractionSelfEvent(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable);
event void FTundraTreeGuardianRangedShootLaunchEvent(UTundraTreeGuardianRangedShootTargetable Targetable, FVector FallbackDirection);

class UTundraTreeGuardianRangedInteractionTargetableComponent : UAutoAimTargetComponent
{
	default MinimumDistance = 1750.0;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere)
	ETundraTreeGuardianRangedInteractionType InteractionType;

	/* If true you can specify a cone where if the TreeGuardian is within it they will be moved out of it. */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "(InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive || InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown)", EditConditionHides))
	bool bLifeGivingMoveOutCone = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "(InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive || InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown) && bLifeGivingMoveOutCone", EditConditionHides))
	float LifeGivingMoveOutConeRadius = 2000.0;

	/* Angle degrees of the full cone arc */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "(InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive || InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown) && bLifeGivingMoveOutCone", EditConditionHides))
	float LifeGivingMoveOutConeAngleDegrees = 30.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "(InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive || InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown) && bLifeGivingMoveOutCone", EditConditionHides))
	float LifeGivingMoveOutSpeed = 600.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "(InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive || InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown) && bLifeGivingMoveOutCone", EditConditionHides))
	bool bLifeGivingMoveOutConeRelativeToTargetable = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple", EditConditionHides))
	bool bStayAtGrapplePointWhenReaching = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive || InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple && bStayAtGrapplePointWhenReaching", EditConditionHides))
	bool bBlockCancel = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple && !bStayAtGrapplePointWhenReaching", EditConditionHides))
	bool bApplyImpulseWhenReaching = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple && !bStayAtGrapplePointWhenReaching && bApplyImpulseWhenReaching", EditConditionHides))
	FVector LocalPlayerImpulseToApplyWhenReaching;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple && !bStayAtGrapplePointWhenReaching && bApplyImpulseWhenReaching", EditConditionHides))
	bool bCounterPlayersCurrentVelocityWhenApplyingImpulse = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple", EditConditionHides))
	bool bOmniDirectionalGrapplePoint = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple", EditConditionHides))
	bool bBlockTargetingWhenGrappleMoving = false;

	UPROPERTY(EditAnywhere)
	bool bBlockTargetingWhenAirborne = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown", EditConditionHides))
	FButtonMashSettings IceKingHoldDownButtonMashSettings;
	default IceKingHoldDownButtonMashSettings.Difficulty = EButtonMashDifficulty::Medium;
	default IceKingHoldDownButtonMashSettings.Duration = 4;
	default IceKingHoldDownButtonMashSettings.bAllowPlayerCancel = false;
	default IceKingHoldDownButtonMashSettings.Mode = EButtonMashMode::ButtonMash;
	default IceKingHoldDownButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
	default IceKingHoldDownButtonMashSettings.bBlockOtherGameplay = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "InteractionType == ETundraTreeGuardianRangedInteractionType::IceKingHoldDown", EditConditionHides))
	bool bIceKingHoldDownBlockDeath = false;

	/* Called as soon as player claims this interaction (called as soon as player releases RT) */
	UPROPERTY()
	FTundraTreeGuardianRangedInteractionEvent OnCommitInteract;

	/* Called when player is actively in interaction, this means different things for different interacts but for grapple points this will be called when grapple point is reached for instance. */
	UPROPERTY()
	FTundraTreeGuardianRangedInteractionEvent OnStartInteract;

	/* Called when the player exits the interaction */
	UPROPERTY()
	FTundraTreeGuardianRangedInteractionEvent OnStopInteract;

	/* Called when the tree guardian actually leaves the grapple point, if the player cancels out of a grapple point this is called at the same time as OnStopInteract, if the player  */
	UPROPERTY()
	FTundraTreeGuardianRangedInteractionEvent OnLeaveGrapplePoint;

	UPROPERTY()
	FTundraTreeGuardianRangedInteractionSelfEvent OnStartLookingAt;

	UPROPERTY()
	FTundraTreeGuardianRangedInteractionSelfEvent OnStopLookingAt;

	UPROPERTY()
	FTundraTreeGuardianRangedShootLaunchEvent OnShootInteractLaunch;

	private bool bInteractingWithThis = false;
	bool bForceExit = false;

	FVector PreviousLocation;
	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		PreviousLocation = WorldLocation;
		if(InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple && bBlockTargetingWhenGrappleMoving)
			SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Velocity = (WorldLocation - PreviousLocation) / DeltaTime;
		PreviousLocation = WorldLocation;
	}

	void CommitInteract()
	{
		bInteractingWithThis = true;
		OnCommitInteract.Broadcast();
	}

	void StartInteract()
	{
		OnStartInteract.Broadcast();
	}

	void StopInteract()
	{
		bInteractingWithThis = false;
		bForceExit = false;
		OnStopInteract.Broadcast();
	}

	void LeaveGrapplePoint()
	{
		OnLeaveGrapplePoint.Broadcast();
	}

	bool IsInteracting()
	{
		return bInteractingWithThis;
	}

	void StartLookingAt()
	{
		OnStartLookingAt.Broadcast(this);
	}

	void StopLookingAt()
	{
		OnStopLookingAt.Broadcast(this);
	}

	UFUNCTION()
	void ForceExitInteract()
	{
		if(InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple)
			devCheck(bStayAtGrapplePointWhenReaching, "Cannot force exit interact since the tree guardian wont stay at it when reaching it.");

		devCheck(InteractionType != ETundraTreeGuardianRangedInteractionType::Shoot, "Cannot force exit interact since we are shooting and that is a one shot event.");
		bForceExit = true;
	}

	UFUNCTION()
	void ForceEnterInteract()
	{
		auto TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Game::Zoe);
		TreeGuardianComp.RangedInteractionTargetableToForceEnter = this;
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);
		
		auto TargetableWidget = Cast<UTundraPlayerTreeGuardianRangedInteractionTargetableWidget>(Widget);

		if(TargetableWidget == nullptr)
			return;

		if(TargetableWidget.bIsPrimaryTarget && !TargetableWidget.WasPrimaryTarget())
		{
			TargetableWidget.OnStartLookingAtInteract(InteractionType, this);
		}
		else if(!TargetableWidget.bIsPrimaryTarget && TargetableWidget.WasPrimaryTarget() )
		{
			TargetableWidget.OnStopLookingAtInteract(InteractionType, this);
		}

		if(TargetableWidget.bIsPrimaryTarget)
			TargetableWidget.LastFrameWasPrimaryTarget = Time::FrameNumber;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Query.Player);

		if(bBlockTargetingWhenAirborne)
		{
			auto MoveComp = UPlayerMovementComponent::Get(Query.Player);
			if(!MoveComp.HasGroundContact() && (TreeGuardianComp == nullptr || TreeGuardianComp.CurrentRangedGrapplePoint == nullptr))
				return false;
		}

		Targetable::ApplyVisibleRange(Query, MaximumDistance);

		if(TreeGuardianComp != nullptr)
		{
			if(TreeGuardianComp.CurrentRangedGrapplePoint == this)
				return false;

			if(TreeGuardianComp.CurrentRangedLifeGivingTargetable == this)
				return false;
		}

		float Dot = ForwardVector.DotProduct((Query.Player.ActorLocation - WorldLocation).GetSafeNormal());
		if(!bOmniDirectionalGrapplePoint && InteractionType == ETundraTreeGuardianRangedInteractionType::Grapple && Dot < 0.0)
			return false;

		// Bail if this target is disabled
		if (!bIsAutoAimEnabled)
			return false;

		// Pre-cull based on total distance, this is technically a bit inaccurate with the shape,
		// but max distances are generally so far that it doesn't matter
		float BaseDistanceSQ = WorldLocation.DistSquared(Query.Player.ActorLocation);
		if (BaseDistanceSQ < Math::Square(MinimumDistance))
			return false;

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.Player.ActorLocation - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if(Angle > MaxAimAngle)
				return false;
		}

		if(InteractionType == ETundraTreeGuardianRangedInteractionType::Shoot)
		{
			Targetable::RequirePlayerCanReachUnblocked(Query);
		}

		// Check if we are actually inside the auto-aim arc
		FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);

		Query.DistanceToTargetable = TargetLocation.Distance(Query.AimRay.Origin);

		// Auto aim angle can change based on distance
		float MaxAngle = CalculateAutoAimMaxAngle(Query.DistanceToTargetable);

#if !RELEASE
		// Show debugging for auto-aim if we want to
		ShowDebug(Query.Player, MaxAngle, Query.DistanceToTargetable);
#endif

		FVector TargetDirection = (TargetLocation - Query.AimRay.Origin).GetSafeNormal();
		float AngularBend = Math::RadiansToDegrees(Query.AimRay.Direction.AngularDistanceForNormals(TargetDirection));

		if (AngularBend > MaxAngle)
		{
			Query.Result.Score = 0.0;
			return true;
		}

		// Score the distance based on how much we have to bend the aim
		Query.Result.Score = (1.0 - (AngularBend / MaxAngle));
		Query.Result.Score /= Math::Pow(Math::Max(Query.DistanceToTargetable, 0.01) / 1000.0, TargetDistanceWeight);

		// Apply bonus to score
		Query.Result.Score *= ScoreMultiplier;

		// If the point is occluded we can't target it,
		// we only do this test if we would otherwise become primary target (performance)
		if (Query.IsCurrentScoreViableForPrimary())
		{
			Targetable::MarkVisibilityHandled(Query);
			return CheckPrimaryOcclusion(Query, TargetLocation);
		}

		return true;
	}
}

#if EDITOR
class UTundraTreeGuardianRangedInteractionTargetableVisualizer : UAutoAimTargetVisualizer
{
	default VisualizedClass = UTundraTreeGuardianRangedInteractionTargetableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto Targetable = Cast<UTundraTreeGuardianRangedInteractionTargetableComponent>(Component);

		if(Targetable.InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive && Targetable.bLifeGivingMoveOutCone)
		{
			DrawArc(Targetable.WorldLocation, Targetable.LifeGivingMoveOutConeAngleDegrees, Targetable.LifeGivingMoveOutConeRadius, Targetable.ForwardVector, FLinearColor::Red, 5, FVector::UpVector, 16, Targetable.MinimumDistance);
		}
	}
}
#endif