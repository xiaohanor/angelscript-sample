UCLASS(Abstract)
class UTopDownPlayerArrowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"TopDownPlayerArrow");
	default TickGroup = EHazeTickGroup::AfterPhysics;

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<TSubclassOf<ATopDownPlayerArrow>> PlayerArrowClass;

	ATopDownPlayerArrow PlayerArrow;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);

		if (PlayerArrowClass[Player].IsValid())
		{
			PlayerArrow = Cast<ATopDownPlayerArrow>(SpawnActor(
				PlayerArrowClass[Player],
				Player.ActorLocation,
				Player.ActorRotation,
			));
			PlayerArrow.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (IsValid(PlayerArrow))
			PlayerArrow.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;
		if (PlayerArrow == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerArrow.SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerArrow.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.IsOnAnyGround())
		{
			// On the ground just go to the player position
			PlayerArrow.SetActorLocationAndRotation(Player.ActorLocation, Player.ActorRotation);
			PlayerArrow.SetActorHiddenInGame(false);
		}
		else
		{
			// Trace where the ground is so the indicator can display on the ground
			// TODO: This could probably use an async trace?
			FHazeTraceSettings Trace;
			Trace.TraceWithPlayer(Player);
			Trace.UseLine();

			auto GroundHit = Trace.QueryTraceSingle(
				Player.ActorLocation + Player.MovementWorldUp * 50.0,
				Player.ActorLocation + Player.MovementWorldUp * -2000.0,
			);

			if (GroundHit.bBlockingHit)
			{
				PlayerArrow.SetActorHiddenInGame(false);
				PlayerArrow.SetActorLocationAndRotation(GroundHit.ImpactPoint, Player.ActorRotation);
			}
			else
			{
				// We didn't find the ground, so hide the indicator
				PlayerArrow.SetActorHiddenInGame(true);
			}
		}
	}
};