
UCLASS(Abstract)
class UGameplay_Gadget_Player_CopsGun_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnWeaponsAttach(FScifiPlayerCopsGunWeaponAttachEventData OnAttachData){}

	UFUNCTION(BlueprintEvent)
	void OnWeaponsDetach(FScifiPlayerCopsGunWeaponDetachEventData OnDetachData){}

	UFUNCTION(BlueprintEvent)
	void OnRecall(){}

	UFUNCTION(BlueprintEvent)
	void ThrowPreImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnShoot(FScifiPlayerCopsGunOnShootEventData OnShootData){}

	/* END OF AUTO-GENERATED CODE */

	AScifiCopsGun Gun;

	UPROPERTY()
	UScifiPlayerCopsGunManagerComponent SciFiCopsGunComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		GetSciFiCopsGunComponent();
	}

	// Cache or Get SciFiCopsGunComponent so we can use it during SD attachment-setup.
	UFUNCTION(BlueprintPure)
	UScifiPlayerCopsGunManagerComponent GetSciFiCopsGunComponent()
	{
		if (SciFiCopsGunComponent != nullptr)
			return SciFiCopsGunComponent;

		SciFiCopsGunComponent = UScifiPlayerCopsGunManagerComponent::Get(PlayerOwner);

		Gun = SciFiCopsGunComponent.Weapons[0];

		return SciFiCopsGunComponent;
	}

	UFUNCTION(BlueprintPure)
	float GetDistanceToCurrentTarget()
	{
		return Gun.GetDistanceToCurrentTarget();
	}

}