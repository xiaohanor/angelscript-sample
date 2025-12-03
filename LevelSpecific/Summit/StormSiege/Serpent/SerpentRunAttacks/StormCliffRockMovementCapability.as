class UStormCliffRockMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStormCliffRock Rock;
	float Gravity;

	FRotator RandomRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rock = Cast<AStormCliffRock>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Rock.bActivated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds > Rock.LifeTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rock.LifeTime += Time::GameTimeSeconds;
		float RPitch = Math::RandRange(-1, 1);
		float RYaw = Math::RandRange(-1, 1);
		float RRoll = Math::RandRange(-1, 1);
		float RSpeed = Math::RandRange(80.0, 160.0);
		RandomRot = FRotator(RPitch, RYaw, RRoll) * RSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Rock.MeshComp.AddLocalRotation(RandomRot * DeltaTime);

		Rock.OutImpulse = Math::FInterpConstantTo(Rock.OutImpulse, 0.0, DeltaTime, 500.0);
		Rock.ActorLocation += Rock.ActorForwardVector * Rock.OutImpulse * DeltaTime;
		Gravity = Math::FInterpConstantTo(Gravity, Rock.MaxGravity, DeltaTime, Rock.MaxGravity / 2.0);
		Rock.ActorLocation -= Rock.ActorUpVector * Gravity * DeltaTime;
	}
};