class UIslandSidescrollerOneWayPlatformCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UIslandSidescrollerComponent SidescrollerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SidescrollerComp.IsInSidescrollerMode())
			return false;

		if(SidescrollerComp.OneWayPlatforms.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SidescrollerComp.IsInSidescrollerMode())
			return true;

		if(SidescrollerComp.OneWayPlatforms.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveComp.RemoveMovementIgnoresActor(this);

		// We must use the player capsule location to get the bottom of the capsule, otherwise our check won't match the player collision.
		const FVector BottomOfCapsuleLocation = Player.CapsuleComponent.WorldLocation - Player.CapsuleComponent.UpVector * Player.CapsuleComponent.BoundsExtent.Z;

		// Ignore platforms where the player is below the platform's top location
		TArray<AActor> ActorsToIgnore;
		for(auto PlatformActor : SidescrollerComp.OneWayPlatforms)
		{
			auto Platform = Cast<AIslandSidescrollerOneWayPlatform>(PlatformActor);
			FVector PlatformTopLocation = Platform.Collision.WorldLocation + FVector::UpVector * Platform.Collision.BoundsExtent.Z;

			if(BottomOfCapsuleLocation.Z < PlatformTopLocation.Z)
				ActorsToIgnore.Add(Platform);
		}

		if(ActorsToIgnore.Num() > 0)
			MoveComp.AddMovementIgnoresActors(this, ActorsToIgnore);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}
}