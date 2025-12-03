struct FGravityBikeWhipThrowableThrownEventData
{
	UGravityBikeWhipThrowTargetComponent ThrowTarget;
}

struct FGravityBikeWhipThrowableHitEventData
{
	UPROPERTY(BlueprintReadOnly, Transient)
	AActor HitActor;

	UPROPERTY(BlueprintReadOnly, Transient)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly, Transient)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly, Transient)
	bool bHitEnemy;

	FGravityBikeWhipThrowableHitEventData(FGravityBikeWhipThrowHitData InHitData)
	{
		HitActor = InHitData.HitActor;
		ImpactPoint = InHitData.ImpactPoint;
		ImpactNormal = InHitData.ImpactNormal;
		bHitEnemy = UGravityBikeSplineEnemyHealthComponent::Get(HitActor) != nullptr;
	}
};

UCLASS(Abstract)
class UGravityBikeWhipThrowableEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UGravityBikeWhipThrowableComponent ThrowableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThrowableComp = UGravityBikeWhipThrowableComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrown(FGravityBikeWhipThrowableThrownEventData EventData)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowHit(FGravityBikeWhipThrowableHitEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDropped()
	{
	}
};