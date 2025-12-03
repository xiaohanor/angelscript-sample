UCLASS(Abstract)
class ADentistDancingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UDentistDancingComponent DancingRoot;

	UPROPERTY(DefaultComponent, Attach = DancingRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = DancingRoot)
	UDentistGooglyEyeSpawnerComponent LeftEyeSpawnerComp;

	UPROPERTY(DefaultComponent, Attach = DancingRoot)
	UDentistGooglyEyeSpawnerComponent RightEyeSpawnerComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 7500;
};