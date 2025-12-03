UCLASS(Abstract)
class UGravityBikeMissileLauncherTargetableWidget : UTargetableWidget
{
	UGravityBikeWeaponUserComponent WeaponComp;
	UGravityBikeMissileLauncherComponent MissileLauncherComp;

	UPROPERTY(BlueprintReadOnly)
	bool bHasCharge = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
		MissileLauncherComp = UGravityBikeMissileLauncherComponent::Get(Player);

		bHasCharge = WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot());
	}

	void OnUpdated() override
	{
		bHasCharge = WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot());

		Super::OnUpdated();
	}
};