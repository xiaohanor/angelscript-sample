class UVillageCanalForwardImpactDeathPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;
}

class UVillageCanalForwardImpactDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeMovementComponent MoveComp;
	UVillageCanalForwardImpactDeathPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerComp = UVillageCanalForwardImpactDeathPlayerComponent::Get(Player);
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
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.UseSphereShape(50.0);

		FHitResult Hit = Trace.QueryTraceSingle(Player.ActorCenterLocation, Player.ActorCenterLocation + (Player.ActorForwardVector * 50.0));

		if (Hit.bBlockingHit)
			Player.KillPlayer(FPlayerDeathDamageParams(-Player.ActorForwardVector), PlayerComp.DeathEffect);
	}
}