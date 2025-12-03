
class UContextualMovesTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"ContextualMoves";
	default UsableByPlayers = EHazeSelectPlayer::Both;

	/* Whether to disable the interaction by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Targetable", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the interaction enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Targetable", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";
	
	//Range at which the point will be actionable
	UPROPERTY(Category = "Settings", EditAnywhere, meta = (ClampMin="0.0"))
	float ActivationRange = 1500.0;

	/*
	 * Allows contextual moves to be visible before they are actionable
	 * At 0, the point will be actionable as soon as you get in range
	 * At 500, the point will be visible for 500 units before you can activate the point
	 */
	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float AdditionalVisibleRange = 800.0;

	/*
	 * Minimum Range to enforce
	 * 0 = no minium range
	 */
	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float MinimumRange = 0.0;

	// Visualization will be drawn by EditRenderedComp rather then ScriptCompVisualizer when enabled
	/*
	 * Should we enable visualization even when point isn't selected (In case you want to align a series of points)
	 */
	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bAlwaysVisualizeRanges = false;

	//Should we check if targetable is obstructed
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	bool bTestCollision = true;

	//Should we ignore the owning actor of the point when testing collision
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions", meta = (EditCondition = "bTestCollision", EditConditionHides))
	bool bIgnorePointOwner = true;

	//Should we perform a player world up check
	UPROPERTY(EditAnywhere, Category = "Targetable|Modified World Up")
	bool bShouldValidateWorldUp = false;

	//How much can player world up deviate from point world up
	UPROPERTY(EditAnywhere, Category = "Targetable|Modified World Up", meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0", EditCondition = "bShouldValidateWorldUp", EditConditionHides))
	float UpVectorCutOffAngle = 15.0;

	//How much can player world up deviate from point world up
	UPROPERTY(EditAnywhere, Category = "Targetable|Modified World Up", meta = (EditCondition = "bShouldValidateWorldUp", EditConditionHides))
	bool bShowWorldUpCutoff = false;

	// Whether the point can only be used if the player is "behind" it, based on the component forward vector
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	bool bRestrictToForwardVector = false;

	// Maximum angle that the player can be from the forward vector to be able to use the point
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions", meta = (ClampMin = "0.0", ClampMax = "180.0", UIMin = "0.0", UIMax = "180.0", EditCondition = "bRestrictToForwardVector", EditConditionHides))
	float ForwardVectorCutOffAngle = 90.0;

	// Restrict whether the point can only be used within a certain angle vertically
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	bool bRestrictVerticalAngle = false;

	// Maximum Vertical Angle that the player can be from the forward vector to be able to use the point
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions", meta = (ClampMin = "0.0", ClampMax = "180.0", UIMin = "0.0", UIMax = "180.0", EditCondition = "bRestrictVerticalAngle", EditConditionHides))
	float VerticalCutOffAngle = 90.0;

	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	EAirActivationSettings AirActivationSettings = EAirActivationSettings::ActivateInAirAndGround;
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions")
	EHeightActivationSettings HeightActivationSettings = EHeightActivationSettings::ActivateBelowAndAbove;

	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions", meta = (EditCondition="HeightActivationSettings != EHeightActivationSettings::ActivateBelowAndAbove", EditConditionHides))
	bool bAllowActivationWithinHeightMargin = false;
	/* Will allow activation outside of the Height condition if within the margin.
	 * Setting 200 = allow activation above point if height difference is <= that value even if set to only below
	 */
	UPROPERTY(EditAnywhere, Category = "Targetable|Conditions", meta = (EditCondition= "bAllowActivationWithinHeightMargin && HeightActivationSettings != EHeightActivationSettings::ActivateBelowAndAbove", EditConditionHides))
	float HeightActivationMargin = 0.0;

	/**
	 * If this targetable becomes the primary target, allow it to be activated from slightly farther away so we don't
	 * immediately lose track of it again if we're hovering near the boundary.
	 */ 
	UPROPERTY(Category = "Settings", EditAnywhere, AdvancedDisplay, meta = (ClampMin="0.0"))
	float ActivationBufferRange = 250.0;

	/**
	 * If checked will not trigger any camera effects (Shakes/Impulses/etc) when interacting with this individual point
	 */
	UPROPERTY(Category = "Settings", EditAnywhere, AdvancedDisplay)
	bool bBlockCameraEffectsForPoint;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!VerifyBaseTargetableConditions(Query))
			return false;
			
		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ApplyTargetableRangeWithBuffer(Query, ActivationRange, ActivationBufferRange);
		Targetable::ScoreLookAtAim(Query, false);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange, ActivationBufferRange);

		if (bTestCollision)
		{
			// Avoid tracing if we are already lower score than the current primary target
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}

	protected float GetWidgetFullSizeRange() const
	{
		return ActivationRange;
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);

		UContextualMovesWidget ContextualWidget = Cast<UContextualMovesWidget>(Widget);
		if (ContextualWidget != nullptr)
		{
			UPlayerTargetablesComponent TargetablesComp = UPlayerTargetablesComponent::Get(Widget.Player);

			float Distance = ContextualWidget.GetWidgetWorldPosition().Distance(
				Widget.Player.ViewLocation + TargetablesComp.TargetingWidgetLocationOffset.Get()
			);

			// Scale the whole widget to be smaller as the player gets further away
			float FullSizeRange = GetWidgetFullSizeRange() + 500;
			if (TargetablesComp.IgnoreVisualWidgetDistance.Get())
				Distance = FullSizeRange;
			float WantedScale = FullSizeRange / Math::Max(Distance, 1.0);

			// Fullscreen and 2D situations don't do this scaling
			if (SceneView::IsFullScreen())
				WantedScale = 1.0;
			else if (Widget.Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
				WantedScale = 1.0;

			float Scale = Math::Clamp(WantedScale, 0.5, 1.0);
			ContextualWidget.SetRenderScale(FVector2D(Scale, Scale));

			// When close by, allow the inner distance on the widget to be increased so it still
			// looks like it's tied to the distance.
			ContextualWidget.DistanceScaleFactor = Math::Max(WantedScale, 1.0);
		}
	}

	bool VerifyBaseTargetableConditions(FTargetableQuery& Query) const
	{
		if (bShouldValidateWorldUp && !ValidatePlayerWorldUp(Query))
			return false;

		if (bRestrictToForwardVector && !ValidateForwardVector(Query))
			return false;

		if (bRestrictVerticalAngle && !ValidateVerticalAngle(Query))
			return false;

		if (MinimumRange > 0.0 && !VerifyOutsideMinimumRange(Query))
			return false;

		if(!VerifyHeightActivationConditions(Query))
			return false;

		if(!VerifyAirActivationSettings(Query))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		if (bStartDisabled)
			Disable(StartDisabledInstigator);
	}

	//Enable the interaction with the instigator set as the start disabled instigator.
	UFUNCTION(Category = "Interaction")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			Enable(StartDisabledInstigator);
	}

	//Check if player world up matches relative up vector of TargetablePoint
	bool ValidatePlayerWorldUp(FTargetableQuery Query) const
	{
		FVector CheckVector = GetUpVector();
		if(CheckVector.DotProduct(Query.PlayerWorldUp) < 0.0)
			return false;

		float Angle = CheckVector.GetAngleDegreesTo(Query.PlayerWorldUp);
		if(Angle > UpVectorCutOffAngle)
			return false;
		else
			return true;
	}

	bool ValidatePlayerWorldUp(AHazePlayerCharacter Player) const
	{
		FVector CheckVector = GetUpVector();
		if(CheckVector.DotProduct(Player.MovementWorldUp) < 0.0)
			return false;

		float Angle = CheckVector.GetAngleDegreesTo(Player.MovementWorldUp);
		if(Angle > UpVectorCutOffAngle)
			return false;
		else
			return true;
	}

	bool ValidateForwardVector(FTargetableQuery Query) const
	{
		FVector Delta = (WorldLocation - Query.Player.ActorLocation).VectorPlaneProject(GetUpVector());
		if (Delta.IsNearlyZero())
			return false;

		float Angle = GetForwardVector().GetAngleDegreesTo(Delta);
		if (Angle > ForwardVectorCutOffAngle)
			return false;
		else
			return true;
	}

	bool ValidateVerticalAngle(FTargetableQuery Query) const
	{
		FVector Delta = (WorldLocation - Query.Player.ActorLocation).VectorPlaneProject(GetRightVector());
		if (Delta.IsNearlyZero())
			return false;

			float Angle = GetForwardVector().GetAngleDegreesTo(Delta);

			if(bRestrictToForwardVector)
			{
				//if we are restricting to forward then we only check in that direction
				if (Angle > VerticalCutOffAngle)
					return false;
				else
					return true;	
			}
			else
			{
				//Check angle from both directions
				FVector CompBackwardsDirection = -GetForwardVector();
				float BackwardsAngle = CompBackwardsDirection.GetAngleDegreesTo(Delta);
				if(Angle > VerticalCutOffAngle && BackwardsAngle > VerticalCutOffAngle)
					return false;
				else
					return true;
			}
	}

	bool VerifyOutsideMinimumRange(FTargetableQuery& Query) const
	{
		return (Query.DistanceToTargetable > MinimumRange);
	}
	
	bool VerifyHeightActivationConditions(FTargetableQuery& Query) const
	{
		FVector PointToPlayerDirection = Query.PlayerLocation - WorldLocation;

		switch(HeightActivationSettings)
		{
			case EHeightActivationSettings::ActivateOnlyAbove:
			case EHeightActivationSettings::ActivateOnlyAboveButVisibleBelow:
				if (PointToPlayerDirection.DotProduct(Query.PlayerWorldUp) < 0)
				{
					float CurrentHeight = PointToPlayerDirection.DotProduct(Query.PlayerWorldUp);
					if (bAllowActivationWithinHeightMargin && CurrentHeight > -HeightActivationMargin)
					{
						return true;
					}
					else
					{
						if (HeightActivationSettings == EHeightActivationSettings::ActivateOnlyAbove)
						{
							return false;
						}
						else
						{
							Query.Result.bPossibleTarget = false;
							Query.Result.VisualProgress *= 1.0 - Math::Saturate(Math::Abs(CurrentHeight + HeightActivationMargin) / (ActivationRange + AdditionalVisibleRange));
							return true;
						}
					}
				}
			break;
			
			case EHeightActivationSettings::ActivateOnlyBelow:
			case EHeightActivationSettings::ActivateOnlyBelowButVisibleAbove:
				if(PointToPlayerDirection.DotProduct(Query.PlayerWorldUp) > 0)
				{
					float CurrentHeight = PointToPlayerDirection.DotProduct(Query.PlayerWorldUp);
					if(bAllowActivationWithinHeightMargin && CurrentHeight < HeightActivationMargin)
					{
						return true;
					}
					else
					{
						if (HeightActivationSettings == EHeightActivationSettings::ActivateOnlyBelow)
						{
							return false;
						}
						else
						{
							Query.Result.bPossibleTarget = false;
							Query.Result.VisualProgress *= 1.0 - Math::Saturate(Math::Abs(CurrentHeight - HeightActivationMargin) / (ActivationRange + AdditionalVisibleRange));
							return true;
						}
					}
				}
			break;
			
			default:
				break;
		}
		return true;
	}

	bool VerifyAirActivationSettings(FTargetableQuery Query) const
	{
		switch (AirActivationSettings)
		{
			case EAirActivationSettings::ActivateOnlyInAir:
				if (Query.PlayerMovementComponent != nullptr)
				{
					if (!Query.PlayerMovementComponent.IsInAir())
						return false;
				}
			break;

			case EAirActivationSettings::ActivateOnlyOnGround:
				if (Query.PlayerMovementComponent != nullptr)
				{
					if (!Query.PlayerMovementComponent.IsOnWalkableGround())
						return false;
				}
			break;
			case EAirActivationSettings::ActivateInAirAndGround:
			break;
		}

		return true;
	}
}

enum EAirActivationSettings
{
	ActivateOnlyInAir,
	ActivateOnlyOnGround,
	ActivateInAirAndGround
}

enum EHeightActivationSettings
{
	ActivateOnlyBelow,
	ActivateOnlyAbove,
	ActivateBelowAndAbove,
	ActivateOnlyBelowButVisibleAbove,
	ActivateOnlyAboveButVisibleBelow,
}