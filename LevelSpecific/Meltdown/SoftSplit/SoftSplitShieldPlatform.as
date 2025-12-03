class ASoftSplitShieldPlatform : AWorldLinkDoubleActor
{
	
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotationComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
			Super::BeginPlay();
	}
};