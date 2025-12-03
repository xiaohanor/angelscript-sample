event void FWieldWeaponSignature(ABasicAIWeapon Weapon);

class UBasicAIWeaponWielderComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Weapon")
	TSubclassOf<ABasicAIWeapon> WeaponClass = nullptr;

	UPROPERTY()
	bool bMaintainWeaponWorldScale = true;

	UPROPERTY()
	float BaseWeaponScale = 1.0;

	FWieldWeaponSignature OnWieldWeapon;

	UPROPERTY(Transient)
	ABasicAIWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (WeaponClass.IsValid())
		{
			Weapon = SpawnActor(WeaponClass, bDeferredSpawn = true, Level = Owner.Level);
			Weapon.MakeNetworked(this);
			FName Socket = AttachSocketName;
			if (!Weapon.AttachSocketOverride.IsNone())
				Socket = Weapon.AttachSocketOverride;
			Weapon.ActorScale3D *= BaseWeaponScale;
			FinishSpawningActor(Weapon);

			// Need to do this after finish spawning, or relative location goes bonkers
			Weapon.AttachToComponent(AttachParent, Socket, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, bMaintainWeaponWorldScale ? EAttachmentRule::KeepWorld : EAttachmentRule::SnapToTarget, true);

			OnWieldWeapon.Broadcast(Weapon);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if (Weapon != nullptr)
			Weapon.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (Weapon != nullptr)
			Weapon.RemoveActorDisable(this);
	}
}	
