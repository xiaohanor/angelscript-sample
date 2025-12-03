event void FOnToothEnderedExitPortalSignature();

class ADentistSideStoryExitActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FOnToothEnderedExitPortalSignature OnBothExitPortal;

	TPerPlayer<bool> bPlayerInRange;
	TPerPlayer<bool> bPlayerEnteredPortal;

	UPROPERTY()
	float Radius = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (bPlayerInRange[Player] && !bPlayerEnteredPortal[Player] && Player.ActorLocation.Distance(ActorLocation) < Radius)
			{
				bPlayerEnteredPortal[Player] = true;

				FVector PlayerDirection = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal();
				FVector Location = ActorLocation + PlayerDirection * Radius;
				FRotator Rotation = FRotator::MakeFromXZ(PlayerDirection, FVector::UpVector);
				BP_OnPlayerEntered(Location, Rotation);
			}
		}
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		if (bPlayerInRange[Player])
			return;
		
		// Player decides when they are in range themselves, sends that over
		if(!Player.HasControl())
			return;
		
		FVector PlayerDirection = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal();
		FVector Location = ActorLocation + PlayerDirection * Radius;
		FRotator Rotation = FRotator::MakeFromXZ(PlayerDirection, FVector::UpVector);

		CrumbPlayerEnteredPortal(Player, Location, Rotation);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbPlayerEnteredPortal(AHazePlayerCharacter Player, FVector WorldLocation, FRotator WorldRotation)
	{
		bPlayerInRange[Player] = true;

		// Host decides when both players are in range, sends that over
		if(HasControl())
		{
			if (bPlayerInRange[Player.OtherPlayer] && !GetIsInDentistChaseGameOver())
				CrumbBothPlayerInPortal();
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_OnPlayerEntered(FVector WorldLocation, FRotator WorldRotation){};

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbBothPlayerInPortal()
	{
		OnBothExitPortal.Broadcast();
		QueueComp.Idle(1.0);
		QueueComp.Event(this, n"HidePlayers");
		QueueComp.ReverseDuration(1.0, this, n"ExpandPortal");	
	}

	UFUNCTION()
	private void HidePlayers()
	{
		for (auto Player : Game::Players)
			Player.BlockCapabilities(CapabilityTags::Visibility, this);
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		QueueComp.Duration(1.0, this, n"ExpandPortal");
	}

	UFUNCTION()
	private void ExpandPortal(float Alpha)
	{
		float CurrentValue = Math::EaseOut(0.01, 1.0, Alpha, 2.0);
		SetActorScale3D(FVector(CurrentValue));
	}

	private bool GetIsInDentistChaseGameOver()
	{
		for (auto Player : Game::Players)
		{
			if (Network::IsGameNetworked())
			{
				bool bIsHost = Network::HasWorldControl() && Player.HasControl();
				bool bIsRemoteHost = !Network::HasWorldControl() && !Player.HasControl();
				bool bIsHostPlayer = bIsHost || bIsRemoteHost;
				if (bIsHostPlayer && Player.IsAnyCapabilityActive(n"DentistChaseGameOver"))
					return true;
			}
			else
			{
				if (Player.IsMio() && Player.IsAnyCapabilityActive(n"DentistChaseGameOver"))
					return true;
			}
		}
		return false;
	}
};