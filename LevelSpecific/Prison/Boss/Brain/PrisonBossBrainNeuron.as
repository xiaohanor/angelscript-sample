UCLASS(Abstract)
class APrisonBossBrainNeuron : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent NeuronRoot;

	UPROPERTY(DefaultComponent, Attach = NeuronRoot)
	UStaticMeshComponent NeuronMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
}