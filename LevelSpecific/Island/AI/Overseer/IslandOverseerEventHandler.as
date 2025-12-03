UCLASS(Abstract)
class UIslandOverseerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttackFloorHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserAttackStart(FIslandOverseerLaserAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserAttackStop(FIslandOverseerLaserAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeAttackTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeAttackImpact(FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeAttackFistImpact(FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeAttackHeadImpact(FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeAttackSpawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorShakeDebrisImpact(FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwipeTelegraphStart(FIslandOverseerSwipeAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwipeTelegraphStop(FIslandOverseerSwipeAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallAttackTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRedBlueHit(FIslandOverseerEventHandlerOnRedBlueHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHeadTakeDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPeekStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPeekEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPeekAttackStart(FIslandOverseerEventHandlerOnPeekAttackStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPeekAttackLaunch(FIslandOverseerEventHandlerOnPeekAttackLaunchData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPeekAttackEnd() {}

	UFUNCTION(BlueprintEvent)
	void OnPeekBombImpact(FIslandOverseerPeekBombOnHitEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFloodPlatformPull() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBeamActivationHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrushableHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTremorImpact(FIslandOverseerEventHandlerOnTremorImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAdvanceStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecloseTakeDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserBombAttackStart(FIslandOverseerLaserAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserBombAttackStop(FIslandOverseerLaserAttackData Data) {}

	UFUNCTION(BlueprintEvent)
	void OnFloodAttackPrepare() {}

	UFUNCTION(BlueprintEvent)
	void OnFloodAttackStart() {}

	UFUNCTION(BlueprintEvent)
	void OnFloodAttackStop() {}

	UFUNCTION(BlueprintEvent)
	void OnMoveStarted() {}

	UFUNCTION(BlueprintEvent)
	void OnMoveStopping() {}

	UFUNCTION(BlueprintEvent)
	void OnMoveStopped() {}

	UFUNCTION(BlueprintEvent)
	void OnLeftEyeExplode() {}

	UFUNCTION(BlueprintEvent)
	void OnRightEyeExplode() {}

	UFUNCTION(BlueprintEvent)
	void OnHeadImpact() {}

	UFUNCTION(BlueprintEvent)
	void OnDeployEyes() {}

	UFUNCTION(BlueprintEvent)
	void OnDropLand() {}

	UFUNCTION(BlueprintEvent)
	void OnHaymakerImpact(FIslandOverseerEventHandlerOnHaymakerImpactData Data) {}
}

struct FIslandOverseerEventHandlerOnHaymakerImpactData
{
	UPROPERTY()
	FVector ImpactLocation;

	FIslandOverseerEventHandlerOnHaymakerImpactData(FVector _ImpactLocation)
	{
		ImpactLocation = _ImpactLocation;
	}
}

struct FIslandOverseerEventHandlerOnRedBlueHitData
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	bool bDead;

	FIslandOverseerEventHandlerOnRedBlueHitData(bool _bDead, FVector _ImpactLocation, FVector _ImpactNormal)
	{
		bDead = _bDead;
		ImpactLocation = _ImpactLocation;
		ImpactNormal = _ImpactNormal;
	}
}

struct FIslandOverseerEventHandlerOnDoorShakeAttackImpactData
{
	UPROPERTY()
	FVector AttackLocation;
}

struct FIslandOverseerEventHandlerOnPeekAttackStartData
{
	UPROPERTY()
	FVector LaunchLocation;
}

struct FIslandOverseerEventHandlerOnPeekAttackLaunchData
{
	UPROPERTY()
	FVector LaunchLocation;
}

struct FIslandOverseerEventHandlerOnTremorImpactData
{
	UPROPERTY()
	FVector LeftHandImpactLocation;

	UPROPERTY()
	FVector RightHandImpactLocation;
}