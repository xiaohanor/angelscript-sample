class ASanctuaryCentipedeLavaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
};