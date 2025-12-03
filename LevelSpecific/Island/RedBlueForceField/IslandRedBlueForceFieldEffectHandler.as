struct FIslandRedBlueForceFieldOnBulletReflectOnForceFieldParams
{
	UPROPERTY()
	FVector WorldImpactLocation;
}

struct FIslandRedBlueForceFieldOnGrenadeDetonateOnForceFieldParams
{
	UPROPERTY()
	FVector GrenadeExplodeLocation;

	UPROPERTY()
	float GrenadeExplodeRadius;
}

struct FIslandRedBlueForceFieldAudioEffectParams
{
	UPROPERTY()
	FVector HoleLocation;
}

UCLASS(Abstract)
class UIslandRedBlueForceFieldEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletReflectOnForceField(FIslandRedBlueForceFieldOnBulletReflectOnForceFieldParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnNewHoleInForceField(FIslandRedBlueForceFieldOnGrenadeDetonateOnForceFieldParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldDestroyed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldActivated() {}

	// Event that only triggers when the first hole starts shrinking (not when the next hole starts shrinking).
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Audio_OnHoleStartShrinking(FIslandRedBlueForceFieldAudioEffectParams Params) {}

	// Event that only triggers when the last hole has finished shrinking and closed.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Audio_OnClosedHole(FIslandRedBlueForceFieldAudioEffectParams Params) {}

	// Event that triggers for all holes that will be closed in 0.5 seconds.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Audio_OnHoleAlmostFullyClosed(FIslandRedBlueForceFieldAudioEffectParams Params) {}
}