class ATundra_River_Stalactite : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach="Root")
	UNiagaraComponent BreakEffect;

	UPROPERTY(DefaultComponent, Attach="Root")
	UStaticMeshComponent Stalactite;

	default Stalactite.SetCollisionProfileName(n"BlockAll", false);
	default Stalactite.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
	default Stalactite.GenerateOverlapEvents = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Stalactite.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		SetActorControlSide(Game::GetZoe());
	}

	UFUNCTION()
	void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		if(HasControl())
		{
			auto Overlapper = Cast<ATundra_River_BreakStalactites>(OtherActor);
			if(Overlapper != nullptr)
			{
				CrumbBreak();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBreak()
	{
		BreakEffect.Activate(true);
		Stalactite.SetHiddenInGame(true);
		SetActorEnableCollision(false);
	}
}