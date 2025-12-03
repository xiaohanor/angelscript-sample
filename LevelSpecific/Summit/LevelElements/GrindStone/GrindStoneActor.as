class AGrindStoneActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.RelativeRotation = FRotator(90.0, 0.0, 0.0);
	default CapsuleComponent.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComponent;

	UPROPERTY(EditAnywhere)
	float Radius = 500.0;

	UPROPERTY()
	float RotationForce = 100.0;

	UPROPERTY(EditAnywhere)
	float Drag = 8.0;

	float RotationSpeed = 0.0;
	float Rotation = 0.0;
	float Input = 0.0;

	TPerPlayer <bool> PendingImpulse;
	TArray<AHazePlayerCharacter> ImpactingPlayers;
	TArray<AHazePlayerCharacter> TeenDragons;



//	UPROPERTY(DefaultComponent)
//	UHazeCapabilityComponent CapabilityComponent;
//	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineControlledRotatorInputCapability");

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CapsuleComponent.SetCapsuleRadius(Radius);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactCallbackComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerImpactStart");
		ImpactCallbackComponent.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerImpactEnd");
		
	}

	UFUNCTION()
	private void PlayerImpactStart(AHazePlayerCharacter Player)
	{
		if (Player == Game::Mio)
		{
			PendingImpulse[Game::Mio] = true;
			//UPlayerTeenDragonComponent DragonComp = UPlayerTeenDragonComponent::Get(Player);
		}
		else
		{
			//UPlayerTeenDragonComponent DragonComp = UPlayerTeenDragonComponent::Get(Player);
			TeenDragons.Add(Player);
		}

	}

	UFUNCTION()
	private void PlayerImpactEnd(AHazePlayerCharacter Player)
	{
		//UPlayerTeenDragonComponent DragonComp = UPlayerTeenDragonComponent::Get(Player);
		TeenDragons.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	PrintScaled("Input: " + Input);
		float PlayerRotationSpeed = 0.0;

		for (auto PlayerDragon : TeenDragons)
		{
			FVector AxisVector = PlayerDragon.MovementWorldUp.CrossProduct(ActorForwardVector);
			PlayerRotationSpeed -= Math::RadiansToDegrees(PlayerDragon.ActorVelocity.DotProduct(AxisVector) / Radius);
			PrintToScreen("Player Velocity: " + PlayerDragon.ActorVelocity.Size());
			PrintScaled("PlayerRotationSpeed:" + PlayerRotationSpeed, 0.0, FLinearColor::Green);

		}
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (PendingImpulse[Player])
			{
				//UPlayerTeenDragonComponent DragonComp = UPlayerTeenDragonComponent::Get(Player);
				FVector Impulse = FVector::UpVector * PlayerRotationSpeed * 100;
				Impulse = Impulse.GetClampedToSize(0,7000);
				Player.AddMovementImpulse(Impulse);
				PendingImpulse[Player] = false;
			}
			
		}


/*
		if (PlayerMovementComponent != nullptr)
		{
			PlayerMovementInput = PlayerMovementComponent.GetMovementInput();
			Debug::DrawDebugLine(PlayerMovementComponent.Owner.ActorLocation, PlayerMovementComponent.Owner.ActorLocation + PlayerMovementInput * 500.0, FLinearColor::Green, 10.0, 0.0);
			FVector AxisVector = PlayerMovementComponent.WorldUp.CrossProduct(ActorForwardVector);

		//	FVector DistanceFromAxis = PlayerMovementComponent.Owner.ActorLocation

			Input = -PlayerMovementInput.DotProduct(AxisVector);
			PrintScaled("Input:" + Input, 0.0);
			PrintScaled("Velocity:" + PlayerMovementComponent.Velocity.Size(), 0.0);
		}
*/

		float Acceleration = PlayerRotationSpeed
						   - RotationSpeed * Drag;

/*
		float Acceleration = Input * RotationForce * (bPlayerContact ? 1.0 : 0.0)
						   - RotationSpeed * Drag;
*/
		RotationSpeed += Acceleration * DeltaSeconds;
	
		AddActorLocalRotation(FRotator(0.0, 0.0, PlayerRotationSpeed * DeltaSeconds));
	}
}