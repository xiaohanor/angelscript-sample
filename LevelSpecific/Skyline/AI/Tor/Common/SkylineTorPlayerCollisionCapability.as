class USkylineTorPlayerCollisionCapability : UHazeCapability
{
	ASkylineTor Tor;
	USkylineTorPlayerCollisionComponent CollisionComp;
	float Scale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Tor = Cast<ASkylineTor>(Owner);
		Tor.PlayerCollision.WorldScale3D = FVector(0, 0, 1);
		CollisionComp = USkylineTorPlayerCollisionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CollisionComp.bEnabled && Scale < 1)
			Scale += DeltaTime * 2;
		else if(!CollisionComp.bEnabled && Scale > 0)
			Scale -= DeltaTime * 2;
		Scale = Math::Clamp(Scale, 0, 1);
		Tor.PlayerCollision.WorldScale3D = FVector(Scale, Scale, 1);
	}
}