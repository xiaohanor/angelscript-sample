class USkylineControlledRotatorInputCapability : UHazeCapability
{
	ASkylineControlledRotator SkylineControlledRotator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkylineControlledRotator = Cast<ASkylineControlledRotator>(Owner);
		CapabilityInput::LinkActorToPlayerInput(SkylineControlledRotator, Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Input = GetAttributeFloat(AttributeNames::LeftStickRawX);
		//FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
	//	PrintScaled("CapabilityInput: " + Input);
		SkylineControlledRotator.Input = -Input;
	}
}

class ASkylineControlledRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.RelativeRotation = FRotator(90.0, 0.0, 0.0);
	default CapsuleComponent.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleComponent GravityBladeGrappleComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityBladeGravityShiftComponent;
	default GravityBladeGravityShiftComponent.Type = EGravityBladeGravityShiftType::Plane;
	default GravityBladeGravityShiftComponent.Axis = FVector::ForwardVector;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComponent;

	UPROPERTY(EditAnywhere)
	float Radius = 500.0;

	UPROPERTY()
	float RotationForce = 300.0;

	UPROPERTY(EditAnywhere)
	float Drag = 8.0;

	UPROPERTY()
	float RotationSpeed = 0.0;
	
	float Rotation = 0.0;
	float Input = 0.0;

	TArray<AHazePlayerCharacter> ImpactingPlayers;

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
		ImpactingPlayers.Add(Player);
	}

	UFUNCTION()
	private void PlayerImpactEnd(AHazePlayerCharacter Player)
	{
		ImpactingPlayers.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	PrintScaled("Input: " + Input);
		float PlayerRotationSpeed = 0.0;

		for (auto Player : ImpactingPlayers)
		{
			FVector AxisVector = Player.MovementWorldUp.CrossProduct(ActorForwardVector);
			PlayerRotationSpeed -= Math::RadiansToDegrees(Player.ActorVelocity.DotProduct(AxisVector) / Radius);
			PrintScaled("PlayerRotationSpeed:" + PlayerRotationSpeed, 0.0, FLinearColor::Green);
			
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

		Rotation += RotationSpeed * DeltaSeconds;
		PrintToScreen(""+ Rotation);
	}
}