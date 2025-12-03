class ATundraFloatingPoleClimbBlockingVolume : ABlockingVolume
{
	default BrushComponent.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	TPerPlayer<UPlayerMovementComponent> MoveComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComps[Game::Mio] = UPlayerMovementComponent::Get(Game::Mio);
		MoveComps[Game::Zoe] = UPlayerMovementComponent::Get(Game::Zoe);

		MoveComps[Game::Mio].AddMovementIgnoresActor(this, this);
		MoveComps[Game::Zoe].AddMovementIgnoresActor(this, this);
	}

	// These are bound in the otter component since that might not be created when running BeginPlay on this actor.
	UFUNCTION()
	private void OnAttachFloatingPole(ATundraFloatingPoleClimbActor FloatingPole)
	{
		MoveComps[Game::Mio].RemoveMovementIgnoresActor(this);
	}

	UFUNCTION()
	private void OnDetachFloatingPole(ATundraFloatingPoleClimbActor FloatingPole)
	{
		MoveComps[Game::Mio].AddMovementIgnoresActor(this, this);
	}
}