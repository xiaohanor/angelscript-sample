class USpaceWalkHookPointComponent : UTargetableComponent
{
	default TargetableCategory = n"SpaceWalkHook";

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float MinimumRange = 0.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float MaximumRange = 7000.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float ActivationBufferRange = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float ExitVelocity = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float HookAcceleration = 3000.0;

	// Whether to try to point the player in the forward direction of the point when launching
	UPROPERTY(EditAnywhere, Category = "Auto Launch Direction")
	bool bUseAutoLaunchCone = false;

	// Maximum angle away from the forward direction of the point to point the player in
	UPROPERTY(EditAnywhere, Category = "Auto Launch Direction", Meta = (EditCondition = "bUseAutoLaunchCone", EditConditionHides))
	float AutoLaunchConeAngle = 10.0;

	// Maximum angle to bend the player into the forward direction from
	UPROPERTY(EditAnywhere, Category = "Auto Launch Direction", Meta = (EditCondition = "bUseAutoLaunchCone", EditConditionHides))
	float AutoLaunchMaxTriggerAngle = 25.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, MaximumRange);
		Targetable::ApplyTargetableRangeWithBuffer(Query, MaximumRange, ActivationBufferRange);
		Targetable::ScoreLookAtAim(Query);

		// Avoid tracing if we are already lower score than the current primary target
		if (!Query.IsCurrentScoreViableForPrimary())
			return false;
		return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = true);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(
			WorldLocation,
			MaximumRange,
			LineColor = FLinearColor::Green,
		);

		if (bUseAutoLaunchCone)
		{
			Debug::DrawDebugArrow(
				WorldLocation,
				WorldLocation + ForwardVector * ExitVelocity,
				ExitVelocity,
				FLinearColor::Yellow,
				10
			);

			Debug::DrawDebugConeInDegrees(
				WorldLocation,
				ForwardVector,
				ExitVelocity,
				AutoLaunchConeAngle,
				AutoLaunchConeAngle,
				LineColor = FLinearColor::Yellow,
			);

			Debug::DrawDebugConeInDegrees(
				WorldLocation,
				-ForwardVector,
				MaximumRange,
				AutoLaunchConeAngle + AutoLaunchMaxTriggerAngle,
				AutoLaunchConeAngle + AutoLaunchMaxTriggerAngle,
				LineColor = FLinearColor::Blue,
			);
		}
	}
#endif
};