class ACoastBossDrillbazzTelegraph : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MeshComp.SetVisibility(false);
};