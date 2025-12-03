UCLASS(Abstract)
class USkylineTorHammerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitGeneral(FSkylineTorHammerOnHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactHit(FSkylineTorHammerOnHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactLand(FSkylineTorHammerOnHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackHit(FSkylineTorHammerOnAttackHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStunnedStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStunnedStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShortStunnedStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShortStunnedStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackAnticipationStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipGrabbedSwing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackAnticipationStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackImpact(FOnSwingAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackTelegraphStart() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackWallHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttackAnticipationStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlAttackTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecover() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecallStart(FSkylineTorHammerOnRecallEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecallStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeHit(FSkylineTorHammerEventHandlerOnBladeHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShieldBreak(FSkylineTorHammerEventHandlerShieldBreakData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShieldStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpiralTelegraphStart(FSkylineTorHammerOnSpiralTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpiralTelegraphUpdate(FSkylineTorHammerOnSpiralTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpiralTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVolleyTelegraphStart(FSkylineTorHammerOnVolleyTelegraphStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVolleyThrow(FSkylineTorHammerOnVolleyTelegraphStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVolleyTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInterruptGrabMashStart(FOnInterruptGrabMashData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInterruptGrabMashStop(FOnInterruptGrabMashData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShockwaveTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShockwaveTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShockwaveAttack(FOnShockwaveAttackData Data) {}
}

struct FOnSwingAttackData
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FRotator ImpactRotation;

	FOnSwingAttackData(FVector _ImpactLocation, FRotator _ImpactRotation)
	{
		ImpactLocation = _ImpactLocation;
		ImpactRotation = _ImpactRotation;
	}
}

struct FOnShockwaveAttackData
{
	UPROPERTY()
	FVector ImpactLocation;

	FOnShockwaveAttackData(FVector _ImpactLocation)
	{
		ImpactLocation = _ImpactLocation;
	}
}


struct FOnInterruptGrabMashData
{
	UPROPERTY()
	AHazeActor Target;

	FOnInterruptGrabMashData(AHazeActor _Target)
	{
		Target = _Target;
	}
}

struct FSkylineTorHammerOnSpiralTelegraphData
{
	UPROPERTY()
	TArray<FSkylineTorHammerSpiralMoveBehaviourTelegraphLocationData> TelegraphLocations;

	UPROPERTY()
	FHazeRuntimeSpline TelegraphSpline;

	FSkylineTorHammerOnSpiralTelegraphData(TArray<FSkylineTorHammerSpiralMoveBehaviourTelegraphLocationData> InTelegraphLocations, FHazeRuntimeSpline _TelegraphSpline)
	{
		TelegraphLocations = InTelegraphLocations;
		TelegraphSpline = _TelegraphSpline;
	}
}


struct FSkylineTorHammerOnLaunchEventData
{
	UPROPERTY()
	FVector LaunchLocation;

	FSkylineTorHammerOnLaunchEventData(FVector InLaunchLocation)
	{
		LaunchLocation = InLaunchLocation;
	}
}

struct FSkylineTorHammerOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSkylineTorHammerOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSkylineTorHammerOnTelegraphData
{
	UPROPERTY()
	FVector TargetLocation;
}

struct FSkylineTorHammerOnAttackHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSkylineTorHammerOnAttackHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSkylineTorHammerEventHandlerOnBladeHitData
{
	UPROPERTY()
	FGravityBladeHitData Hit;

	FSkylineTorHammerEventHandlerOnBladeHitData(FGravityBladeHitData InHit)
	{
		Hit = InHit;
	}
}

struct FSkylineTorHammerEventHandlerShieldBreakData
{
	UPROPERTY()
	FGravityBladeHitData Hit;

	UPROPERTY()
	USceneComponent AttachComponent;

	FSkylineTorHammerEventHandlerShieldBreakData(FGravityBladeHitData InHit, USceneComponent _AttachComponent)
	{
		Hit = InHit;
		AttachComponent = _AttachComponent;
	}
}

struct FSkylineTorHammerOnVolleyTelegraphStartData
{
	UPROPERTY()
	FVector TelegraphLocation;

	FSkylineTorHammerOnVolleyTelegraphStartData(FVector _TelegraphLocation)
	{
		TelegraphLocation = _TelegraphLocation;
	}
}

struct FSkylineTorHammerOnRecallEventData
{
	UPROPERTY()
	float RecallDistance;

	FSkylineTorHammerOnRecallEventData(float _RecallDistance)
	{
		RecallDistance = _RecallDistance;
	}
}
