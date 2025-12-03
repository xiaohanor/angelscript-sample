class UIslandShieldotronDamagePlayerOnTouchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"DamagePlayerOnTouch");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UIslandShieldotronSettings Settings;

	UBasicAIHealthComponent HealthComp;
	
	private TPerPlayer<float> HitPlayerCooldownTimer;
	AHazeCharacter OwnerCharacter;

	float OwnerRadius;
	float OwnerHalfHeight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		OwnerCharacter = Cast<AHazeCharacter>(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);

		OwnerRadius = OwnerCharacter.CapsuleComponent.CapsuleRadius;
		OwnerHalfHeight = OwnerCharacter.CapsuleComponent.CapsuleHalfHeight;
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
				HitPlayerCooldownTimer[Player] = Settings.DamageOnTouchHitCooldown;
				
				Player.DealTypedDamage(Owner, Settings.DamageOnTouchDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

				FVector KnockdownDir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				FKnockdown Knockdown;
				Knockdown.Duration = Settings.DamageOnTouchKnockdownDuration;
				Knockdown.Move = KnockdownDir * Settings.DamageOnTouchKnockdownDist;
				Player.ApplyKnockdown(Knockdown);
				Player.SetActorRotation((-Knockdown.Move).ToOrientationQuat());
			}
		}
	}

	private bool IsOverlappingPlayer(AHazePlayerCharacter Player)	
	{
		float PlayerHalfHeight = Player.CapsuleComponent.CapsuleHalfHeight;
		float PlayerRadius = Player.CapsuleComponent.CapsuleRadius;

		// check 2D-dist
		if (Player.ActorCenterLocation.Dist2D(Owner.ActorCenterLocation) > PlayerRadius + OwnerRadius)
			return false;

		// Check player bottom above top
		if (Player.ActorCenterLocation.Z - PlayerHalfHeight > Owner.ActorCenterLocation.Z + OwnerHalfHeight)
			return false;

		// Check player top below bottom
		if (Player.ActorCenterLocation.Z + PlayerHalfHeight < Owner.ActorCenterLocation.Z - OwnerHalfHeight)
			return false;

		return true;
	}

}