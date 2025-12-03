struct FSkylineAllyLaunchFanOverlapParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USkylineAllyLaunchFanEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFanActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFanDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerOverlap(FSkylineAllyLaunchFanOverlapParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEndOverlap(FSkylineAllyLaunchFanOverlapParams Params) {}
}

class ASkylineAllyLaunchFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FanBladeMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent TriggerComp;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	FHazeTimeLike SpinTimeLike;
	default SpinTimeLike.UseSmoothCurveZeroToOne();
	default SpinTimeLike.Duration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float UpForce = 6000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ToCenterForce = 1.0;

	UPROPERTY(EditAnywhere, Category = "Targetable")
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent MioActionQueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ZoeActionQueueComp;

	UPROPERTY(EditAnywhere, Category = "Temp")
	bool bAutoActivate = false;
	UPROPERTY(EditAnywhere, Category = "Temp")
	bool bPluggedIn = true;

	UPROPERTY(EditAnywhere)
	float TargetHeight = 1000.0;

	UPROPERTY(EditAnywhere)
	float TeleportDuration = 0.8;

	bool bActivated = false;

	TPerPlayer<bool > bPlayerOverlapping;
	TPerPlayer<bool > bPlayerBeingLaunched;

	float Speed = 0.0;

	TPerPlayer<FVector> StartVelocity;
	TPerPlayer<FVector> StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
		SpinTimeLike.BindUpdate(this, n"SpinTimeLikeUpdate");

		if(bPluggedIn)
		HandleActivated(nullptr);

		
		if (bAutoActivate)
			bActivated = true;
	}

	UFUNCTION()
	private void SpinTimeLikeUpdate(float CurrentValue)
	{
		Speed = 1000.0 * CurrentValue;
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                  const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (IsValid(Player) && Player.IsSelectedBy(UsableByPlayers))
		{
			if (bPlayerBeingLaunched[Player])
				return;

			FSkylineAllyLaunchFanOverlapParams Params;
			Params.Player = Player;
			
			USkylineAllyLaunchFanEventHandler::Trigger_OnPlayerOverlap(this, Params);

			bPlayerOverlapping[Player] = true;

			if (bActivated)
				LaunchPlayer(Player);
		}
	}

	

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (IsValid(Player) && Player.IsSelectedBy(UsableByPlayers))
		{
			FSkylineAllyLaunchFanOverlapParams Params;
			Params.Player = Player;
			
			USkylineAllyLaunchFanEventHandler::Trigger_OnPlayerEndOverlap(this, Params);

			bPlayerOverlapping[Player] = false;
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		BPActivated();
		bActivated = true;
		SpinTimeLike.Play();

		USkylineAllyLaunchFanEventHandler::Trigger_OnFanActivated(this);

		for (auto Player : Game::Players)
		{
			if (bPlayerOverlapping[Player])
				LaunchPlayer(Player);
		}
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		BPDeactivated();
		bActivated = false;
		SpinTimeLike.Reverse();

		USkylineAllyLaunchFanEventHandler::Trigger_OnFanDeactivated(this);
	}

	private void LaunchPlayer(AHazePlayerCharacter Player)
	{
		//if (Time::GameTimeSeconds < OverlappedAtGameTime[Player] + Cooldown)
		//	return;

		//	OverlappedAtGameTime[Player] = Time::GameTimeSeconds;
			
			bPlayerBeingLaunched[Player] = true;

			StartVelocity[Player] = ActorTransform.InverseTransformVectorNoScale(Player.ActorVelocity);
			StartLocation[Player] = ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			//Player.SetActorVelocity(ActorForwardVector * TargetHeight / TeleportDuration);

			//Player.BlockCapabilities(CapabilityTags::Movement, this);

			if (Player == Game::Mio)
			{
				MioActionQueueComp.Duration(TeleportDuration, this, n"SetMioLocationUpdate");
				MioActionQueueComp.Event(this, n"MioTeleportFinished");
			}
			else
			{
				ZoeActionQueueComp.Duration(TeleportDuration, this, n"SetZoeLocationUpdate");
				ZoeActionQueueComp.Event(this, n"ZoeTeleportFinished");
			}
	}

	UFUNCTION()
	private void SetMioLocationUpdate(float Alpha)
	{
		SetPlayerTeleportLocation(Alpha, Game::Mio);
		Game::Mio.SetFrameForceFeedback(0.1, 0.1, 0.1, 0.1);
	}

	UFUNCTION()
	private void SetZoeLocationUpdate(float Alpha)
	{
		SetPlayerTeleportLocation(Alpha, Game::Zoe);
		Game::Zoe.SetFrameForceFeedback(0.1, 0.1, 0.1, 0.1);
	}

	UFUNCTION()
	private void MioTeleportFinished()
	{
		PlayerTeleportFinished(Game::Mio);
	}

	UFUNCTION()
	private void ZoeTeleportFinished()
	{
		PlayerTeleportFinished(Game::Zoe);
	}

	private void SetPlayerTeleportLocation(float Alpha, AHazePlayerCharacter Player)
	{
		float LocationBlendAlpha = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);

		FVector LerpedStartLocation = Math::Lerp(StartLocation[Player], 
												StartLocation[Player] + StartVelocity[Player] * TeleportDuration,
												Alpha);

		FVector LerpedTargetLocation = Math::Lerp(FVector::ZeroVector,
												FVector::ForwardVector * TargetHeight,
												Alpha);
		

		FVector NewLocation = Math::Lerp(LerpedStartLocation, LerpedTargetLocation, LocationBlendAlpha);

		if (NewLocation.X < TriggerComp.RelativeLocation.X)
			NewLocation.X = TriggerComp.RelativeLocation.X;

		NewLocation = ActorTransform.TransformPositionNoScale(NewLocation);

		PrintToScreen("WorldLocation = " + NewLocation);

		Player.SetActorLocation(NewLocation);
	}

	private void PlayerTeleportFinished(AHazePlayerCharacter Player)
	{
		Player.SetActorVelocity(ActorForwardVector * TargetHeight / TeleportDuration);
		//Player.SetActorLocation(ActorLocation + ActorForwardVector * TargetHeight);

		bPlayerBeingLaunched[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FanBladeMeshComp.AddRelativeRotation(FRotator(0.0, 0.0, Speed * DeltaSeconds));
	}

	UFUNCTION(BlueprintEvent)
	private void BPActivated(){}

	UFUNCTION(BlueprintEvent)
	private void BPDeactivated(){}
}