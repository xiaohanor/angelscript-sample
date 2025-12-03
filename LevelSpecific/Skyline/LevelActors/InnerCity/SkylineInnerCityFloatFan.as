class ASkylineInnerCityFloatFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent TriggerComp;


	UPROPERTY(EditAnywhere, Category = "Settings")
	float UpForce = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ToCenterForce = 1.0;

	UPROPERTY(EditAnywhere, Category = "Targetable")
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;

	bool bMioOverlapping = false;

	bool bZoeOverlapping = false;

	float Speed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");


	}


	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                  const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (IsValid(Player) && Player.IsSelectedBy(UsableByPlayers))
		{
			if (Player == Game::Mio)
			{
				FSkylineAllyLaunchFanOverlapParams Params;
				Params.Player = Player;

				bMioOverlapping = true;
			}

			if (Player == Game::Zoe)
			{
				FSkylineAllyLaunchFanOverlapParams Params;
				Params.Player = Player;

				bZoeOverlapping = true;
			}
		}
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (IsValid(Player) && Player.IsSelectedBy(UsableByPlayers))
		{
			if (Player == Game::Mio)
			{
				FSkylineAllyLaunchFanOverlapParams Params;
				Params.Player = Player;

				bMioOverlapping = false;
			}
			if(Player == Game::Zoe)
			{
				FSkylineAllyLaunchFanOverlapParams Params;
				Params.Player = Player;

				bZoeOverlapping = false;
			}
		
		}
	}




	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if (bZoeOverlapping)
		{
			auto Zoe = Game::GetZoe();
			FVector ToCenterVector = (ActorLocation - Zoe.ActorLocation) * FVector(1.0, 1.0, 0.0) * ToCenterForce;
			Zoe.AddMovementImpulse(ToCenterVector * DeltaSeconds);
			Zoe.AddMovementImpulse(ActorForwardVector * UpForce * DeltaSeconds);
		}

		if (bMioOverlapping)
		{
			auto Mio = Game::GetMio();
			FVector ToCenterVector = (ActorLocation - Mio.ActorLocation) * FVector(1.0, 1.0, 0.0) * ToCenterForce;
			Mio.AddMovementImpulse(ToCenterVector * DeltaSeconds);
			Mio.AddMovementImpulse(ActorForwardVector * UpForce * DeltaSeconds);
		}
	}
}