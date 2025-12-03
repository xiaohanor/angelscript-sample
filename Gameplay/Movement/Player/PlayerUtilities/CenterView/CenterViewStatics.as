struct FCenterViewApplyForcedTargetParams
{
	/**
	 * Actor with a UCenterViewTargetComponent. If none exists, it will be created at the actor location.
	 */
	UPROPERTY()
	AActor Actor = nullptr;

	UPROPERTY()
	bool bRequireInputToActivate = false;

	UPROPERTY()
	bool bAllowCenterViewInputToDeactivate = false;

	UPROPERTY()
	bool bAllowCameraInputToDeactivate = false;

	UPROPERTY()
	bool bClearOnDeactivate = false;

	UPROPERTY()
	bool bShowTutorial = true;
}

/**
 * Apply a CenterViewTarget, ignoring targeting conditions, and optionally forcing it without requiring input.
 */
UFUNCTION(BlueprintCallable, DisplayName = "Apply Forced Center View Target")
void BP_ApplyForcedCenterViewTarget(AHazePlayerCharacter Player, FCenterViewApplyForcedTargetParams Params, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto CenterViewPlayerComp = UCenterViewPlayerComponent::Get(Player);
	if(CenterViewPlayerComp == nullptr)
		return;

	FCenterViewForcedTarget ForcedTarget;
	ForcedTarget.Instigator = Instigator;
	ForcedTarget.Priority = Priority;
	ForcedTarget.Target = UCenterViewTargetComponent::GetOrCreate(Params.Actor);
	ForcedTarget.Params = Params;

	CenterViewPlayerComp.ApplyForcedTarget(ForcedTarget);
}

mixin void ApplyForcedCenterViewTarget(AHazePlayerCharacter Player, FCenterViewForcedTarget ForcedTarget)
{
	auto CenterViewPlayerComp = UCenterViewPlayerComponent::Get(Player);
	if(CenterViewPlayerComp == nullptr)
		return;

	CenterViewPlayerComp.ApplyForcedTarget(ForcedTarget);
}

UFUNCTION(BlueprintCallable)
mixin void ClearForcedCenterViewTarget(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto CenterViewPlayerComp = UCenterViewPlayerComponent::Get(Player);
	if(CenterViewPlayerComp == nullptr)
		return;

	CenterViewPlayerComp.ClearForcedTarget(Instigator);
}