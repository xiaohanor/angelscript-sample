struct FIslandPortalGenericEffectParams
{
	UPROPERTY()
	AIslandPortal Portal;
}

struct FIslandPortalPlayerEnterEffectParams
{
	UPROPERTY()
	AIslandPortal OriginPortal;

	UPROPERTY()
	AIslandPortal DestinationPortal;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FIslandPortalBulletEnterEffectParams
{
	UPROPERTY()
	AIslandPortal OriginPortal;

	UPROPERTY()
	AIslandPortal DestinationPortal;

	UPROPERTY()
	AIslandRedBlueWeaponBullet Bullet;
}

struct FIslandPortalGrenadeEnterEffectParams
{
	UPROPERTY()
	AIslandPortal OriginPortal;

	UPROPERTY()
	AIslandPortal DestinationPortal;

	UPROPERTY()
	AIslandRedBlueStickyGrenade Grenade;
}

UCLASS(Abstract)
class UIslandPortalEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClosePortal(FIslandPortalGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnter(FIslandPortalPlayerEnterEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletEnter(FIslandPortalBulletEnterEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrenadeEnter(FIslandPortalGrenadeEnterEffectParams Params) {}
}