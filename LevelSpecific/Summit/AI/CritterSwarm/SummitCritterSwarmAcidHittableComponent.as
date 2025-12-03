class USummitCritterSwarmAcidHittableComponent : UHazeSphereCollisionComponent
{
	default SphereRadius = 3000.0;
	default CollisionProfileName = n"NoCollision";
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceEnemy, ECollisionResponse::ECR_Ignore);
	default SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
}
