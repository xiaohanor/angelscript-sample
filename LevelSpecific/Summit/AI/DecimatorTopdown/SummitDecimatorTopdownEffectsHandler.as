struct FDecimatorTopDownSpinChargeImpactParams
{
	UPROPERTY()
	float Strength = 0.0;
}

UCLASS(Abstract)
class USummitDecimatorTopdownEffectsHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeakPointHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitBySpikebomb() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBeginPhaseOne() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInvulnerableStateStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInvulnerableStateStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinChargeStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinChargeImpactWall(FDecimatorTopDownSpinChargeImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinChargeStop() {}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphNewSpearShower() {};

	UFUNCTION(BlueprintEvent)
	void OnStartNewSpearShower() {};

	UFUNCTION(BlueprintEvent)
	void OnSpearShowerFinished() {};

	UFUNCTION(BlueprintEvent)
	void OnShockwave() {};

	UFUNCTION(BlueprintEvent)
	void OnKnockedOut() {};

	UFUNCTION(BlueprintEvent)
	void OnRecoverFromKnockout() {};

	UFUNCTION(BlueprintEvent)
	void OnPermaKnockedOut() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHeadMelted() {}

	
	//
	// Player trap events duplicated from trap's own effects handler for use with audio. Vfx should use the PlayerTrapEffectsHandler.
	//

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrapCrystalSmashed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrapMelted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrapCrystalTrapped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrapMetalTrapped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrapTelegraphStarted(FSummitDecimatorTopdownPlayerTrapTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrapTelegraphStopped(FSummitDecimatorTopdownPlayerTrapTelegraphParams Params) {}

}