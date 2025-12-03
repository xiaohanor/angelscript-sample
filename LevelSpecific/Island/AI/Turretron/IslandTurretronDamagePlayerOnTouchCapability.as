// Damage player close to Turretron.
class UIslandTurretronDamagePlayerOnTouchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"DamagePlayerOnTouch");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UIslandTurretronSettings Settings;

	UBasicAIHealthComponent HealthComp;
	UBasicAIProjectileLauncherComponent LauncherComp;

	private TPerPlayer<float> HitPlayerCooldownTimer;
	AHazeCharacter OwnerCharacter;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		LauncherComp = UBasicAIProjectileLauncherComponent::Get(Owner);
		OwnerCharacter = Cast<AHazeCharacter>(Owner);
		Settings = UIslandTurretronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.IsDead())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HitPlayerCooldownTimer[Game::Mio] = 0.0;
		HitPlayerCooldownTimer[Game::Zoe] = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandlePlayerOverlap(DeltaTime);
	}

	private void HandlePlayerOverlap(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			HitPlayerCooldownTimer[Player] -= DeltaTime;
			if (HitPlayerCooldownTimer[Player] > 0.0)
				continue;

			// Deal damage and apply knockdown
			if (IsOverlappingPlayer(Player))
			{
				HitPlayerCooldownTimer[Player] = Settings.ContactDamagePlayerCooldown;
				
				Player.DealTypedDamage(Owner, Settings.ContactDamageAmount, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

				FVector KnockdownDir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				FKnockdown Knockdown;
				Knockdown.Duration = Settings.ContactDamageKnockdownDuration;
				Knockdown.Move = KnockdownDir * Settings.ContactDamageKnockdownDistance;
				Player.ApplyKnockdown(Knockdown);
				Player.SetActorRotation((-Knockdown.Move).ToOrientationQuat());
			}
		}
	}

	private bool IsOverlappingPlayer(AHazePlayerCharacter Player)
	{
		float Dist = 150;
		FVector ToPlayer = (Owner.ActorCenterLocation - Player.ActorCenterLocation).GetSafeNormal();
		if (ToPlayer.DotProduct(Owner.ActorForwardVector) < 0.45) // Adjust range for when player enages from the side or from behind.
			Dist = 115;
		const float DistSquared = Dist * Dist;
		if (Owner.ActorCenterLocation.DistSquared(Player.ActorCenterLocation) < DistSquared)
			return true;
		if (Owner.ActorCenterLocation.DistSquared(Player.ActorLocation) < DistSquared)
			return true;
		float LauncherDistSquared = 60 * 60;
		if (LauncherComp.WorldLocation.DistSquared(Player.ActorCenterLocation) < LauncherDistSquared)
			return true;

		return false;
	}

}