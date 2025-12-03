namespace AudioSharedProjectiles
{
	float GetProjectileImpactAngle(const FVector ToProjectile, const FVector ImpactNormal)
	{
		return 1.0 - ToProjectile.GetSafeNormal().DotProduct(ImpactNormal);
	}
}

struct FProjectileSharedImpactAudioParams
{
	UPROPERTY()
	AActor HitActor = nullptr;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float NormalAngle;
}

UCLASS(Abstract)
class UGameplay_Weapon_Projectile_Impact_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Trigger_OnProjectileImpact(FProjectileSharedImpactAudioParams ProjectileSharedImpactAudioParams){}

	/* END OF AUTO-GENERATED CODE */

	private TMap<FName, UHazeAudioEvent> CachedEvents;

	UPROPERTY(EditDefaultsOnly)
	bool bLinkToProxy = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = bLinkToProxy))
	EWeaponUser WeaponUser = EWeaponUser::None;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AHazePlayerCharacter PlayerWeaponUser = nullptr;
		switch(WeaponUser)
		{
			case(EWeaponUser::Mio): PlayerWeaponUser = Game::GetMio(); break;
			case(EWeaponUser::Zoe): PlayerWeaponUser = Game::GetZoe(); break;
			default: break;
		
		}

		if(PlayerWeaponUser != nullptr)
			ProxyEmitterSoundDef::LinkToActor(this, PlayerWeaponUser);
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetMaterialImpactEvent(const FName MaterialTag, UHazeAudioEvent DefaultEvent)
	{
		UHazeAudioEvent FoundEvent;
		CachedEvents.Find(MaterialTag, FoundEvent);

		if(FoundEvent == nullptr)
		{
			FString EventName = f"Play_Projectile_Bullet_Shared_Material_Impact_{MaterialTag}";
			if(Audio::GetAudioEventAssetByName(FName(EventName), FoundEvent))
			{
				CachedEvents.Add(MaterialTag, FoundEvent);
			}
			else
			{
				FoundEvent = DefaultEvent;
			}
		}

		return FoundEvent;
	}
}