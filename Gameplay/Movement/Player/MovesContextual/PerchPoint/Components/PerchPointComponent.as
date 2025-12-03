
event void FOnPlayerStartedPerchingOnPointEventSignature(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint);
event void FOnPlayerStoppedPerchingOnPointEventSignature(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint);

enum EPerchPointLandingAssistStrength
{
	Default,
	Weak,
	Minimal,
}

UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/PerchIconBillboardGradient.PerchIconBillboardGradient", EditorSpriteOffset = "X=0 Y=0 Z=65"))
class UPerchPointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"Jump";
	default ActivationRange = 450.0;
	default AdditionalVisibleRange = 750.0;
	default GrappleType = EGrapplePointVariations::PerchPoint;
	default UsableByPlayers = EHazeSelectPlayer::Both;
	default HeightActivationSettings = EHeightActivationSettings::ActivateBelowAndAbove;
	default bTestCollision = false;
	default bVisualizeComponent = true;

	access EditAndReadOnly = private, * (editdefaults, readonly);

	UPROPERTY(EditAnywhere, Category = "Settings")
	UPlayerPerchSettings PerchSettings;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset PerchCameraSetting;
	
	// If true, this perch point allows camera assistance if that is activated
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bAllowPerchCameraAssist = true;

	/*
	 * Should perching be allowed on point
	 * If false then interact will move player to the point and exit with input based speed rather then perching
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAllowPerch = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	access:EditAndReadOnly bool bAllowAutoJumpTo = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	access:EditAndReadOnly bool bAllowGrappleToPoint = true;

	//Should the player camera follow the rotation of the perchpoint if moving
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShouldCameraFollowPointRotation = true;

	/*
	 * This Range will be added inbetween ActivationRange and AdditionalVisibleRange
	 * While in this range a grapple to target will be triggered rather then PerchJumpTo
	 */
	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition = "bAllowGrappleToPoint", EditConditionHides))
	float AdditionalGrappleRange = 1250.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition = "bAllowGrappleToPoint", EditConditionHides))
	float GrappleMinimumRange = 300.0;

	/**
	 * We only trigger an automatic jumpto when the player is in range and the movement input is
	 * within this angle of the direction to the perch point.
	 * Larger angles make it easier to jump to the perch point, but can cause unexpected behavior for the player.
	 */
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bAllowAutoJumpTo", EditConditionHides))
	float MaximumHorizontalJumpToAngle = 30.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, AdvancedDisplay, Category = "Settings")
	access:EditAndReadOnly
	EPerchPointLandingAssistStrength LandingAssistStrength = EPerchPointLandingAssistStrength::Default;

	/**
	 * Maximum angle we can make vertically to automatically jump to the point.
	 */
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay, Meta = (EditCondition = "bAllowAutoJumpTo", EditConditionHides))
	float MaximumVerticalJumpToAngle = 30.0;

	// Ignore the perch spline's movement for the purposes of entering it
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bIgnorePerchMovementDuringEnter = false;

	//Should you be able to interrupt the jump to with AirJump/Dash
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bBlockAirActionCancel = true;

	//when jumping off point, should you inherit any upwards velocity
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bInheritUpwardsVelocity = false;

	//when jumping off point, should you inherit any upwards velocity
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bForcePerchGrappleExit = false;

	// Don't use any camera or input based aiming for this swing point, only target by closest distance
	UPROPERTY(Category = "Targetable", EditAnywhere, AdvancedDisplay)
	bool bTargetByDistanceOnly = false;

	UPROPERTY()
	FOnPlayerStartedPerchingOnPointEventSignature OnPlayerStartedPerchingEvent;
	UPROPERTY()
	FOnPlayerStoppedPerchingOnPointEventSignature OnPlayerStoppedPerchingEvent;
	UPROPERTY()
	FOnPlayerStartedPerchingOnPointEventSignature OnPlayerInitiatedJumpToEvent;

	//Should point be moved along spline
	bool bMovePoint = true;

	TPerPlayer<bool> IsPlayerOnPerchPoint;
	TPerPlayer<bool> IsPlayerLandingOnPoint;
	TPerPlayer<bool> IsPlayerJumpingToPoint;

	UPROPERTY(NotEditable, NotVisible)
	bool bHasConnectedSpline = false;
	UPROPERTY(NotEditable, NotVisible)
	APerchSpline ConnectedSpline;

	bool CanTriggerGrappleEnter(AHazePlayerCharacter Player) const override
	{
		// If we are closer than the normal activation range, we don't want to do a grapple,
		// but the PerchJumpToCapability takes over when pressing RB as well
		float Distance = Player.ActorLocation.Distance(WorldLocation);

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		auto PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		auto JumpComp = UPlayerJumpComponent::GetOrCreate(Player);

		if (!MoveComp.IsOnWalkableGround() && !JumpComp.IsInJumpGracePeriod() && !PerchComp.IsCurrentlyPerching())
			return true;

		return Distance >= ActivationRange;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!VerifyBaseTargetableConditions(Query))
			return false;

		if (!VerifyBaseGrappleConditions(Query))
			return false;

		if(!VerifyAirActivationSettings(Query))
			return false;

		if(!VerifyHeightActivationConditions(Query))
			return false;

		if (IsPlayerJumpingToPoint[Query.Player] || IsPlayerLandingOnPoint[Query.Player])
			return false;

		//Exclude if already perching on
		if (IsPlayerOnPerchPoint[Query.Player])
			return false;

		const bool bUseAutoJumpTargeting = (Query.QueryCategory == n"Jump");
		if (bUseAutoJumpTargeting)
		{
			if (!bAllowAutoJumpTo)
				return false;

			Targetable::ApplyTargetableRange(Query, ActivationRange);
			Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
			Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange);

			Targetable::ScoreWantedMovementInput(Query, MaximumHorizontalJumpToAngle, MaximumVerticalJumpToAngle, bUseNonLockedMovementInput = true);
		}
		else
		{
			if (!bAllowGrappleToPoint)
				return false;
			if (Query.DistanceToTargetable < GrappleMinimumRange)
				return false;

			Targetable::ApplyTargetableRangeWithBuffer(Query, ActivationRange + AdditionalGrappleRange, ActivationBufferRange);
			Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalGrappleRange + AdditionalVisibleRange);
			Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalGrappleRange + AdditionalVisibleRange, ActivationRange + AdditionalGrappleRange, ActivationBufferRange);

			if (bTargetByDistanceOnly)
				Targetable::ApplyDistanceToScore(Query);
			else
				Targetable::ScoreLookAtAim(Query);
		}

		if (bTestCollision)
			return Targetable::RequirePlayerCanReachUnblocked(Query, bIgnorePointOwner);

		return true;
	}

	float GetWidgetFullSizeRange() const override
	{
		return ActivationRange + AdditionalGrappleRange;
	}

	// This targetable can be in both the contextual and the jump assist categories at the same time
	// That way 
	void ApplyTargetableRegistration(UPlayerTargetablesComponent PlayerComp, bool bRegister) override
	{
		if (bRegister)
		{
			if (bAllowAutoJumpTo)
				PlayerComp.RegisterTargetable(n"Jump", this);
			if (bAllowGrappleToPoint)
				PlayerComp.RegisterTargetable(n"ContextualMoves", this);
		}
		else
		{
			if (bAllowAutoJumpTo)
				PlayerComp.UnregisterTargetable(n"Jump", this);
			if (bAllowGrappleToPoint)
				PlayerComp.UnregisterTargetable(n"ContextualMoves", this);
		}
	}

	bool CanAutoJumpTo() const
	{
		return bAllowAutoJumpTo && ActivationRange > 0;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	FTransform GetHorizontalLandOnTransform(AHazePlayerCharacter Player) const
	{
		return WorldTransform;
	}

	FTransform GetVerticalLandOnTransform(AHazePlayerCharacter Player) const
	{
		return WorldTransform;
	}

	FTransform GetJumpToTargetTransform(AHazePlayerCharacter Player) const
	{
		return WorldTransform;
	}

	FVector GetLocationForVelocity() const
	{
		return WorldLocation;
	}
}