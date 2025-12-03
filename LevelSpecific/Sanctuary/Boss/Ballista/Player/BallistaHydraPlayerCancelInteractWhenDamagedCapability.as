class UBallistaHydraPlayerCancelInteractWhenDamagedCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerHealthComponent HealthComp;
	UPlayerInteractionsComponent InteractionsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Player);
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		HealthComp.OnPlayerTookDamage.AddUFunction(this, n"PlayerTakenDamage");
	}

	UFUNCTION()
	private void PlayerTakenDamage(AHazePlayerCharacter DamagedPlayer, float DamageAmount)
	{
		if (IsActive())
		{
			if (InteractionsComp.ActiveInteraction != nullptr)
			{
				ASanctuaryHydraKillerBallista Ballista = Cast<ASanctuaryHydraKillerBallista>(InteractionsComp.ActiveInteraction.Owner);
				if (Ballista != nullptr && Ballista.ProjectileActor != nullptr)
					Ballista.ProjectileActor.CompanionsStopInvestigate();
			}
			InteractionsComp.KickPlayerOutOfAnyInteraction();
			DamagedPlayer.ApplyKnockdown(InteractionsComp.Owner.ActorForwardVector * -1000.0 + FVector::UpVector * 500.0, 2.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (InteractionsComp.ActiveInteraction == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (InteractionsComp.ActiveInteraction == nullptr)
			return true;
		return false;
	}
};