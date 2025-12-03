struct FSkylineBossDamageEventData
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}

struct FSkylineBossFootEventData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineBossLeg Leg;

	UPROPERTY(BlueprintReadOnly)
	FVector FootLocation;

	UPROPERTY(BlueprintReadOnly)
	FRotator FootRotation;

	UPROPERTY(BlueprintReadOnly)
	USkylineBossFootTargetComponent FootTargetComponent;
}

struct FSkylineBossLegEventData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineBossLeg Leg;
	
	UPROPERTY(BlueprintReadOnly)
	FVector FootLocation;

	UPROPERTY(BlueprintReadOnly)
	FRotator FootRotation;
};

struct FSkylineBossCoreDamagedEventData
{
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent HitComponent;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USkylineBossEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	ASkylineBoss Boss = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShieldImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloseHatch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CoreDamaged(FSkylineBossCoreDamagedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CoreDestroyed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PendingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeginFall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FootPlacingStart(FSkylineBossFootEventData FootEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FootLifted(FSkylineBossFootEventData FootEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FootPlaced(FSkylineBossFootEventData FootEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LegDamaged(FSkylineBossLegEventData LegEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LegRestored(FSkylineBossLegEventData LegEventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ImpactPoolStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketBarrageStartShooting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketBarrageStopShooting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DamagingTripod(FSkylineBossDamageEventData DamageData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TripodPhaseOneStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TripodFirstFall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TripodRise() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TripodSecondFall() {}

	UFUNCTION(BlueprintPure)
	AHazeActor GetTarget() const
	{
		return Boss.LookAtTarget.Get();
	}
}