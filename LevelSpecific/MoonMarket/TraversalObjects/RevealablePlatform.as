class ARevealablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoonMarketBobbingSceneComponent BobbingSceneComp;
	default BobbingSceneComp.MinBobSpeed = 0.65;
	default BobbingSceneComp.MaxBobSpeed = 1.25;
	default BobbingSceneComp.BobAmount = 15.0;

	UPROPERTY(DefaultComponent, Attach = BobbingSceneComp)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 3.0;
	default TranslateComp.SpringStrength = 0.5;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsConeRotateComponent ConeComp;
	default ConeComp.Friction = 3.0;
	default ConeComp.SpringStrength = 0.5;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 50.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.25;

	UPROPERTY(DefaultComponent, Attach = ConeComp, ShowOnActor)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = ConeComp, ShowOnActor)
	UStaticMeshComponent CollisionComp;
	default CollisionComp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UInheritVelocityComponent InheritVelocityComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMoonMarketRevealableComponent RevealComp;
	default RevealComp.bCanCollide = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 1800;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UNiagaraComponent FX_Loop;

	float EmissionRate = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		EmissionRate = Math::FInterpConstantTo(EmissionRate, RevealComp.bIsVisible ? 8 : 0, DeltaSeconds, 10);
		
		FX_Loop.SetFloatParameter(n"EmissionRate", EmissionRate);
	}
};