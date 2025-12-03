class ASummitMageGroundBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default BoxComp.SetGenerateOverlapEvents(true);
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default MeshComp.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MagicSystem;
	default MagicSystem.SetAutoActivate(false);

	float ActivationDuration = 2.0;
	float ActivationTime;
	float TimeSinceActive = 0.0;
	float GrowthAlpha;

	float AttackDuration = 0.5;
	float AttackFinishTime;
	float DestroyWaitDuration = 1.0;
	float DestroyTime;

	FVector StartingScale;

	bool bActivatedAttack;
	bool bCanCheckDestroy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingScale = MeshComp.GetRelativeScale3D();
		MeshComp.SetRelativeScale3D(FVector(0.0, 0.0, StartingScale.Z));
		ActivationTime = Time::GameTimeSeconds + ActivationDuration;

		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Time::GameTimeSeconds < ActivationTime)
		{
			TimeSinceActive += DeltaTime;
			GrowthAlpha = TimeSinceActive / ActivationDuration;
			MeshComp.SetRelativeScale3D(FVector(StartingScale.X * GrowthAlpha, StartingScale.Y * GrowthAlpha, 0.05));
		}
		else
		{
			if (!bActivatedAttack)
			{
				BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
				bActivatedAttack = true;
				MagicSystem.Activate();

				AttackFinishTime = Time::GameTimeSeconds + AttackDuration;

				bCanCheckDestroy = true;
				DestroyTime = Time::GameTimeSeconds + DestroyWaitDuration;

				MeshComp.SetHiddenInGame(true);
			}
		}

		if (bCanCheckDestroy)
		{
			if (Time::GameTimeSeconds > DestroyTime)
			{
				DestroyActor();
			}
		}
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!bActivatedAttack)
			return;

		if (Time::GameTimeSeconds < AttackFinishTime)
			return;

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(OtherActor);
	
		if (HealthComp != nullptr)
		{
			HealthComp.DamagePlayer(20.0, nullptr, nullptr);
		}
	}
}