class UPlayerGroundImpactDeathCapability : UHazePlayerCapability
{
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 50;

	UHazeMovementComponent MoveComp;
	UPlayerGroundImpactDeathComponent ImpactDeathComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		ImpactDeathComp = UPlayerGroundImpactDeathComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.IsOnAnyGround())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FPlayerDeathDamageParams Params;
		Params.bIsFallingDeath = false;
		if (MoveComp.GroundContact.IsValidBlockingHit())
		{
			Params.ImpactDirection = MoveComp.GroundContact.ImpactNormal;
		}
		else
		{
			Params.ImpactDirection = Player.MovementWorldUp;
		}
		Params.ForceScale = 5.0;
		Player.KillPlayer(Params, ImpactDeathComp.DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}

class UPlayerGroundImpactDeathComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;
}