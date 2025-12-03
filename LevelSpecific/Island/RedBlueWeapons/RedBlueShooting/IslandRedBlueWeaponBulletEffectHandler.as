struct FIslandRedBlueWeaponBulletForceFieldEffectHandlerInfo
{
	UPROPERTY()
	FVector BulletHoleLocation;

	UPROPERTY()
	float BulletHoleRadius;

	/* True if this bullet created this hole, false if this bullet only made it bigger */
	UPROPERTY()
	bool bHoleWasJustCreated;
}

struct FIslandRedBlueWeaponForceFieldEffectHandlerInfo
{
	UPROPERTY()
	AIslandRedBlueForceField ForceFieldActor;

	/* True if this bullet can make holes in the force field, if not it will impact the shield and not make any holes. */
	UPROPERTY()
	bool bCurrentBulletCanMakeHoles;

	UPROPERTY()
	bool bForceFieldReflectsBullets;

	UPROPERTY()
	TArray<FIslandRedBlueWeaponBulletForceFieldEffectHandlerInfo> HitForceFieldBulletHoles;
}

struct FIslandRedBlueWeaponOnBulletImpactParams
{
	UPROPERTY()
	EIslandRedBlueWeaponType WeaponType;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	FVector BulletLocation;

	UPROPERTY()
	TArray<UIslandRedBlueImpactResponseComponent> ResponseComponents;

	UPROPERTY()
	UPhysicalMaterial PhysMat;

	UPROPERTY()
	FIslandRedBlueWeaponForceFieldEffectHandlerInfo ForceFieldInfo;
}

struct FIslandRedBlueWeaponOnBulletImpactAIParams
{
	UPROPERTY()
	EIslandRedBlueWeaponType WeaponType;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	FVector BulletLocation;

	UPROPERTY()
	AActor HitActor;

	UPROPERTY()
	UPhysicalMaterial PhysMat;
}

UCLASS(Abstract)
class UIslandRedBlueWeaponBulletEffectHandler : UHazeEffectEventHandler
{
	// Called when the bullet impacts something
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletImpact(FIslandRedBlueWeaponOnBulletImpactParams Params) {}

	// Called when the bullets impacts a non-AI
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletImpactNonAI(FIslandRedBlueWeaponOnBulletImpactAIParams Params) {}

	// Called when the bullets impacts an AI
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletImpactAI(FIslandRedBlueWeaponOnBulletImpactAIParams Params) {}

	// Called when the bullet reflects off of an AI's force field
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletReflectedAI(FIslandRedBlueWeaponOnBulletImpactParams Params) {}
}