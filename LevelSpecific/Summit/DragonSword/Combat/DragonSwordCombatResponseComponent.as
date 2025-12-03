struct FDragonSwordHitData
{
	FDragonSwordHitData(){};
	
	FDragonSwordHitData(FVector InImpactPoint, FVector InImpactNormal, FVector InHitDirection, EDamageType InDamageType)
	{
		ImpactPoint = InImpactPoint;
		ImpactNormal = InImpactNormal;
		HitDirection = InHitDirection;
		DamageType = InDamageType;
		bWasOuterRadiusDamage = false;
		AttackType = EDragonSwordCombatAttackType::Ground;
	}

	UPROPERTY(BlueprintReadOnly)
	float Damage;

	UPROPERTY(BlueprintReadOnly)
	EDamageType DamageType;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly)
	FVector HitDirection;

	UPROPERTY(BlueprintReadOnly)
	EDragonSwordCombatAttackType AttackType;

	UPROPERTY(BlueprintReadOnly)
	bool bWasOuterRadiusDamage;
}
struct FDragonSwordHitDataSimple
{
	UPROPERTY(BlueprintReadOnly)
	FVector HitDirection;

	UPROPERTY(BlueprintReadOnly)
	EDamageType DamageType;
}

enum EDragonSwordResponseDetailLevel
{
	None,
	Simple,
	Full
}

event void FDragonSwordHitSignature(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator);
event void FDragonSwordSimpleHitSignature(FDragonSwordHitDataSimple HitDataSimple);
event void FDragonSwordHitNoDataSignature();
class UDragonSwordCombatResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Called when the player hits the object with an attack.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FDragonSwordHitSignature OnHit;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FDragonSwordSimpleHitSignature OnSimpleHit;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FDragonSwordHitNoDataSignature OnHitNoData;

	EDragonSwordResponseDetailLevel ResponseDetailLevel;

	UPROPERTY()
	bool bCanTakeDamageFromOuterRadius = true;

	bool WillDieFromHit(FDragonSwordHitData HitData) const
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (HealthComp == nullptr)
			return false;

		return HealthComp.CurrentHealth < HitData.Damage;
	}

	void Hit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		if (HitData.bWasOuterRadiusDamage && !bCanTakeDamageFromOuterRadius)
			return;

		OnHit.Broadcast(CombatComp, HitData, Instigator);
	}

	void HitSimple(FDragonSwordHitDataSimple HitDataSimple)
	{
		OnSimpleHit.Broadcast(HitDataSimple);
	}

	void HitNoData()
	{
		OnHitNoData.Broadcast();
	}
}