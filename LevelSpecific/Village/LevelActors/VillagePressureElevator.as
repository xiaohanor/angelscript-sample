event void FVillagePressureElevatorEvent();

UCLASS(Abstract)
class AVillagePressureElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;
}