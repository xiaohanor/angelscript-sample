class ASkylineBallBossChargeLaserInteractLocation : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DebugMesh;
	default DebugMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default DebugMesh.SetVisibility(false);
}