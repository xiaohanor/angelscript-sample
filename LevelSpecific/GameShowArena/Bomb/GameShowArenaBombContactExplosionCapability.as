class UGameShowArenaBombContactExplosionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Collision);
	default CapabilityTags.Add(n"BombContactExplosion");

	default TickGroup = EHazeTickGroup::Gameplay;
	AGameShowArenaBomb Bomb;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Bomb.HasExplosionBlock())
			return false;

		if (!MoveComp.HasAnyValidBlockingContacts())
			return false;

		if (Bomb.State.Get() != EGameShowArenaBombState::Thrown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Bomb.State.Get() != EGameShowArenaBombState::Exploding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
			Bomb.CrumbExplode(Bomb.ActorLocation);

#if EDITOR
		auto Page = TEMPORAL_LOG(Bomb).Page("Contacts");
		if (MoveComp.HasGroundContact())
			Page.HitResults("GroundContact", MoveComp.GroundContact.ConvertToHitResult(), MoveComp.CollisionShape);

		if (MoveComp.HasWallContact())
			Page.HitResults("WallContact", MoveComp.WallContact.ConvertToHitResult(), MoveComp.CollisionShape);

		if (MoveComp.HasCeilingContact())
			Page.HitResults("CeilingContact", MoveComp.CeilingContact.ConvertToHitResult(), MoveComp.CollisionShape);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};