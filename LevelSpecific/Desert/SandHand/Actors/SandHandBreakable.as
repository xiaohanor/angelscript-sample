class ASandHandBreakable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USandHandWeakPointStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USandHandResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	USandHandAutoAimTargetComponent AutoAimComp;

}