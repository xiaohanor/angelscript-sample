class AMeltdownWorldSpinPhysicsObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetSimulatePhysics(true);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.SetEnableGravity(false);

		auto MoveComp = UPlayerMovementComponent::Get(Game::Zoe);
		MoveComp.AddMovementIgnoresActor(this, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Mesh.AddForce(FVector(-250.0, 0.0, 0.0), bAccelChange = true);
		Mesh.AddForce(Game::Zoe.GetGravityDirection() * 900.0, bAccelChange = true);
	}
};