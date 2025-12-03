class ASkylineDroneBossScatterProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Mesh.bCanEverAffectNavigation = false;
	default Mesh.bGenerateOverlapEvents = false;

	// How much damage the projectile deals to players.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Projectile")
	float PlayerDamage = 0.1;

	// How much damage the projectile deals to the boss.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Projectile")
	float BossDamage = 0.01;
}