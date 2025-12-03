class ASoftSplitDestructionDoubleActor : AWorldLinkDoubleActor
{

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
};