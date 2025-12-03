struct FIslandRedBlueStickyGrenadeOnDetonateParams
{
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	UPROPERTY()
	FVector ExplosionOrigin;

	UPROPERTY()
	float ExplosionRadius;

	UPROPERTY()
	AActor AttachParentActor;
}

struct FIslandRedBlueStickyGrenadeOnThrowParams
{
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	UPROPERTY()
	FVector GrenadeLocation;
}

struct FIslandRedBlueStickyGrenadeOnDespawnOnForceFieldParams
{
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	UPROPERTY()
	FVector GrenadeLocation;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

struct FIslandRedBlueStickyGrenadeOnAttachedParams
{
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	UPROPERTY()
	FVector GrenadeLocation;

	UPROPERTY()
	UPrimitiveComponent AttachParent;

	UPROPERTY()
	AActor AttachParentActor;

	UPROPERTY()
	UPhysicalMaterial PhysMat;
}

struct FIslandRedBlueStickyGrenadeOnBounceOffParams
{
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	UPROPERTY()
	FHitResult BounceOffHit;

	UPROPERTY()
	FVector NewVelocity;
}

struct FIslandRedBlueStickyGrenadeBasicEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;
}

struct FIslandRedBlueStickyGrenadeEnterPortalEffectParams
{
	UPROPERTY()
	AIslandPortal OriginPortal;

	UPROPERTY()
	AIslandPortal DestinationPortal;
}

UCLASS(Abstract)
class UIslandRedBlueStickyGrenadeEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	AIslandRedBlueStickyGrenade Grenade;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Grenade = Cast<AIslandRedBlueStickyGrenade>(Owner);
		PlayerOwner = Grenade.PlayerOwner;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowGrenade(FIslandRedBlueStickyGrenadeOnThrowParams Params) {}

	// Same as OnThrowGrenade but this event is broadcasted for both players each time a grenade is thrown
	UFUNCTION(BlueprintEvent)
	void OnThrowGrenadeAudio(FIslandRedBlueStickyGrenadeOnThrowParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetonate(FIslandRedBlueStickyGrenadeOnDetonateParams Params) {}

	// Will trigger when the grenade hits a wrong colored force field/enemy shield
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDespawnOnForceField(FIslandRedBlueStickyGrenadeOnDespawnOnForceFieldParams Params) {}

	// Will trigger when the grenades are disabled (after an explosion or if they are just despawned)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResetGrenade(FIslandRedBlueStickyGrenadeBasicEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPrePortalTeleport(FIslandRedBlueStickyGrenadeEnterPortalEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPostPortalTeleport(FIslandRedBlueStickyGrenadeEnterPortalEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttached(FIslandRedBlueStickyGrenadeOnAttachedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttachedAudio(FIslandRedBlueStickyGrenadeOnAttachedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounceOffSurface(FIslandRedBlueStickyGrenadeOnBounceOffParams Params) {}
}

UCLASS(Abstract)
class UIslandRedBlueStickyGrenadeResponseEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttached(FIslandRedBlueStickGrenadeOnAttachedData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetonate(FIslandRedBlueStickyGrenadeOnDetonateParams Params) {}
}