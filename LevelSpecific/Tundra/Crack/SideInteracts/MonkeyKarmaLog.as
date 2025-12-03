class AMonkeyKarmaLog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UBoxComponent BoxComp;
	default BoxComp.BoxExtent = FVector(300, 150, 150);
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteract;
	default PunchInteract.AmountOfPunchesToComplete = MAX_int32;

	TPerPlayer<float> TimeHitPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PunchInteract.OnPunch.AddUFunction(this, n"OnPunched");
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxOverlap");
	}

	UFUNCTION()
	private void OnBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                          const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Time::GetGameTimeSince(TimeHitPlayers[Player]) < 1)
			return;

		if (Math::Abs(TranslateComp.GetVelocity().Size()) < 100)
			return;


		TimeHitPlayers[Player] = Time::GameTimeSeconds;

		FVector HorizontalImpulse = TranslateComp.GetVelocity().GetSafeNormal() * 3000;
		FPlayerLaunchToParameters LaunchParams;
		
		LaunchParams.LaunchImpulse = HorizontalImpulse + FVector::UpVector * 1000;
		LaunchParams.Type = EPlayerLaunchToType::LaunchWithImpulse;
		LaunchParams.Duration = 1.0;
		Player.LaunchPlayerTo(this, LaunchParams);
	}

	UFUNCTION()
	private void OnPunched(FVector PlayerLocation)
	{
		FVector ToBox = (MeshComp.WorldLocation - PlayerLocation).GetSafeNormal();
		TranslateComp.ApplyImpulse(MeshComp.WorldLocation, ToBox * 30000);
	}
};