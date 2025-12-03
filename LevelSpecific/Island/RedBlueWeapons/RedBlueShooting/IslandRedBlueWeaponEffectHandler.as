struct FIslandRedBlueWeaponOnShootParams
{
	UPROPERTY()
	EIslandRedBlueWeaponType WeaponType;

	UPROPERTY()
	FVector MuzzleLocation;

	UPROPERTY()
	FVector ShootDirection;

	UPROPERTY()
	AIslandRedBlueWeaponBullet Bullet;
}

struct FIslandRedBlueWeaponOnShootGrenadeParams
{
	UPROPERTY()
	EIslandRedBlueWeaponType WeaponType;

	UPROPERTY()
	FVector MuzzleLocation;

	UPROPERTY()
	FVector ShootDirection;

	UPROPERTY()
	AIslandRedBlueStickyGrenade Grenade;
}

UCLASS(Abstract)
class UIslandRedBlueWeaponEffectHandler : UHazeEffectEventHandler
{
	private UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent;

	UPROPERTY(BlueprintReadOnly, Transient, NotVisible)
	AIslandRedBlueWeapon WeaponOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponOwner = Cast<AIslandRedBlueWeapon>(Owner);
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(WeaponOwner.PlayerOwner);
	}

	// Called when a bullet is shot from the weapon
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootBullet(FIslandRedBlueWeaponOnShootParams Params) {}

	// Called when the input of the grenade is actually triggered
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootGrenade(FIslandRedBlueStickyGrenadeOnThrowParams Params) {}

	// Called when the reload starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReloadStarted() {}

	// Called when the reload finishes
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReloadFinished() {}

	// Called when the weapon is attached to the hand
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponAttachToHand() {}

	// Called when the weapon is attached to the thigh
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponAttachToThigh() {}

	UFUNCTION(BlueprintPure)
	float GetOverheatAlpha() const property
	{
		return OverheatUserComponent.OverheatAlpha;
	}
}