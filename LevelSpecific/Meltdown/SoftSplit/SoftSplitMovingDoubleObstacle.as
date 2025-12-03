class ASoftSplitMovingDoubleObstacle : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UPROPERTY(EditAnywhere)
	float Speed = 10;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

//	default ActorTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Super::BeginPlay();
		SetActorTickEnabled(false);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(ActorForwardVector * Speed);
	}
};