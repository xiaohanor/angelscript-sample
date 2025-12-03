struct FGravityBikeWeaponImpactData
{
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent HitComponent;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly)
	EGravityBikeWeaponType WeaponType;

	UPROPERTY(BlueprintReadOnly)
	float Damage;

	UPROPERTY(BlueprintReadOnly)
	AHazeActor Instigator;

	FGravityBikeWeaponImpactData(
		UPrimitiveComponent InHitComponent, 
		FVector InImpactPoint, 
		FVector InImpactNormal, 
		EGravityBikeWeaponType InWeaponType,
		float InDamage,
		AHazeActor InInstigator
	)
	{
		HitComponent = InHitComponent;
		ImpactPoint = InImpactPoint;
		ImpactNormal = InImpactNormal;
		WeaponType = InWeaponType;
		Damage = InDamage;
		Instigator = InInstigator;
	}
};

event void FGravityBikeWeaponProjectileResponse(FGravityBikeWeaponImpactData ImpactData);

class UGravityBikeWeaponProjectileResponseComponent : UActorComponent
{
	UPROPERTY()
	FGravityBikeWeaponProjectileResponse OnImpact;
};