UCLASS(Abstract)
class AGoldenAppleCore : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CoreRoot;

	UPROPERTY(DefaultComponent, Attach = CoreRoot)
	UCapsuleComponent PhysicsRoot;
	default PhysicsRoot.SimulatePhysics = true;
}