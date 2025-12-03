// Damage player overlapping Punchotron. Tag is blocked by attacks during action phase.
class UIslandPunchotronDamagePlayerOnTouchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"DamagePlayerOnTouch");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UIslandPunchotronSettings Settings;

	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	
	private TPerPlayer<float> HitPlayerCooldownTimer;
	AHazeCharacter OwnerCharacter;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		OwnerCharacter = Cast<AHazeCharacter>(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
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
		// TODO: throttle number of overlap checks
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
		UCapsuleComponent PlayerCapsule = Player.CapsuleComponent;

		if (IslandPunchotron::IsPlayerDashing(Player))
			return false;		

		bool bIsIntersecting = Overlap::QueryShapeOverlap(
			FCollisionShape::MakeCapsule(OwnerCharacter.CapsuleComponent.CapsuleRadius, OwnerCharacter.CapsuleComponent.CapsuleHalfHeight),
			OwnerCharacter.CapsuleComponent.WorldTransform,
			FCollisionShape::MakeCapsule(PlayerCapsule.CapsuleRadius, PlayerCapsule.CapsuleHalfHeight),
			PlayerCapsule.WorldTransform			
		);

		return bIsIntersecting;
	}

}