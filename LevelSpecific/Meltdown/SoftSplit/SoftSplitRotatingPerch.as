class ASoftSplitRotatingPerch : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UPROPERTY(EditAnywhere)
	float Speed = 10;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent Rotator;

	UPROPERTY(EditAnywhere)
	APerchSpline PerchSpline;

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