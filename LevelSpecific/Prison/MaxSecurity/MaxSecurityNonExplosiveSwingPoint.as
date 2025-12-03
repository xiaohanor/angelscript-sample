UCLASS(Abstract)
class AMaxSecurityNonExplosiveSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SwingPointRoot;

	UPROPERTY(DefaultComponent, Attach = SwingPointRoot, ShowOnActor)
	USwingPointComponent SwingPointComp;
}