class UBasicAIMeleeWeaponComponent : UStaticMeshComponent
{
	default CollisionProfileName = n"NoCollision";
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default bCanEverAffectNavigation = false;

	FBasicBehaviourCooldown Cooldown;
}