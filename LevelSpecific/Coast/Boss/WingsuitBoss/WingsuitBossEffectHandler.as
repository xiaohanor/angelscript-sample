struct FWingsuitShootMachineGunBulletEffectParams
{
	UPROPERTY()
	FVector MuzzleLocation;

	UPROPERTY()
	FVector Direction;

	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	USceneComponent ComponentToAttachTo;

	UPROPERTY()
	FName SocketName;
}

struct FWingsuitMachineGunBulletImpactEffectParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	bool bImpactOnWater;
}

UCLASS(Abstract)
class UWingsuitBossEffectHandler : UHazeEffectEventHandler
{
	// The enemy has fired a single rocket.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootRocket() {}

	// The enemy has fired a multi rocket (5 rockets towards the player)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootMultiRocket() {}

	// When the boss shoots a mine
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootAirMine() {}

	// When the boss shoots a mine
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootMine() {}

	UFUNCTION()
	void AttachEffectToTrain(USceneComponent EffectComp)
	{
		AWingsuitBoss Boss = Cast<AWingsuitBoss>(Owner);
		if (Boss.TargetCart != nullptr)
			EffectComp.AttachToComponent(Boss.TargetCart.Root, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootMachineGunBullet(FWingsuitShootMachineGunBulletEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMachineGunBulletImpact(FWingsuitMachineGunBulletImpactEffectParams Params) {}
}
