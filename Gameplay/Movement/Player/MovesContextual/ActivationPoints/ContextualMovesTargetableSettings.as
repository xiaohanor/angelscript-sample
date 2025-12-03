struct FContextualMovesTargetableSettings
{
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

	void ApplyToTargetable(UContextualMovesTargetableComponent Component)
	{
		Component.bStartDisabled = bStartDisabled;
		Component.StartDisabledInstigator = StartDisabledInstigator;
		Component.ActivationRange = ActivationRange;
		Component.AdditionalVisibleRange = AdditionalVisibleRange;
		Component.MinimumRange = MinimumRange;
		Component.bAlwaysVisualizeRanges = bAlwaysVisualizeRanges;
		Component.bTestCollision = bTestCollision;
		Component.bIgnorePointOwner = bIgnorePointOwner;
		Component.bShouldValidateWorldUp = bShouldValidateWorldUp;
		Component.UpVectorCutOffAngle = UpVectorCutOffAngle;
		Component.bShowWorldUpCutoff = bShowWorldUpCutoff;
		Component.bRestrictToForwardVector = bRestrictToForwardVector;
		Component.ForwardVectorCutOffAngle = ForwardVectorCutOffAngle;
		Component.AirActivationSettings = AirActivationSettings;
		Component.HeightActivationSettings = HeightActivationSettings;
		Component.bAllowActivationWithinHeightMargin = bAllowActivationWithinHeightMargin;
		Component.HeightActivationMargin = HeightActivationMargin;
	}

	void GatherFromTargetable(UContextualMovesTargetableComponent Component)
	{
		bStartDisabled = Component.bStartDisabled;
		StartDisabledInstigator = Component.StartDisabledInstigator;
		ActivationRange = Component.ActivationRange;
		AdditionalVisibleRange = Component.AdditionalVisibleRange;
		MinimumRange = Component.MinimumRange;
		bAlwaysVisualizeRanges = Component.bAlwaysVisualizeRanges;
		bTestCollision = Component.bTestCollision;
		bIgnorePointOwner = Component.bIgnorePointOwner;
		bShouldValidateWorldUp = Component.bShouldValidateWorldUp;
		UpVectorCutOffAngle = Component.UpVectorCutOffAngle;
		bShowWorldUpCutoff = Component.bShowWorldUpCutoff;
		bRestrictToForwardVector = Component.bRestrictToForwardVector;
		ForwardVectorCutOffAngle = Component.ForwardVectorCutOffAngle;
		AirActivationSettings = Component.AirActivationSettings;
		HeightActivationSettings = Component.HeightActivationSettings;
		bAllowActivationWithinHeightMargin = Component.bAllowActivationWithinHeightMargin;
		HeightActivationMargin = Component.HeightActivationMargin;
	}
}