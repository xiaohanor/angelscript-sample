UCLASS(Abstract)
class AGoatDevourableCorn : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CornRoot;

	UPROPERTY(DefaultComponent, Attach = CornRoot)
	UCapsuleComponent CollisionComp;
	default CollisionComp.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	UGoatDevourResponseComponent DevourResponseComp;
}