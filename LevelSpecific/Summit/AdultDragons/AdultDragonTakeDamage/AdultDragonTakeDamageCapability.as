struct FAdultDragonTakeDamageActivationParams
{
	FHitResult Impact;
	UAdultDragonTakeDamageDestructibleRocksComponent DestructibleRockComp;
	EAdultDragonTakeDamageActivationType ActivationType;
}

enum EAdultDragonTakeDamageActivationType
{
	None,
	Damage,
	Kill,
	DestroyRock
}
// TODO Rename to take flight damage
// Handles damage and death when colliding in the level
class UAdultDragonTakeDamageCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"AdultDragonTakeDamageCapability");

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAdultDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;
	UCameraUserComponent CameraComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraComp = UCameraUserComponent::Get(Player);
		// TODO Add damage effects
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	// UFUNCTION(BlueprintOverride)
	// void PreTick(float DeltaTime)
	// {
	// 	FVector VelocityConstrained = MoveComp.Velocity.ConstrainToDirection(Player.ActorForwardVector);
	// 	float Size = VelocityConstrained.Size();
	// 	PrintToScreen(f"{Size=}");		
	// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAdultDragonTakeDamageActivationParams& Params) const
	{
		if (!MoveComp.HasAnyValidBlockingContacts())
			return false;

		FHitResult HitResult;

		if (MoveComp.HasGroundContact())
			HitResult = MoveComp.GetGroundContact().ConvertToHitResult();

		if (MoveComp.HasWallContact())
			HitResult = MoveComp.GetWallContact().ConvertToHitResult();

		if (MoveComp.HasCeilingContact())
			HitResult = MoveComp.GetCeilingContact().ConvertToHitResult();

		if (!HitResult.bBlockingHit)
			return false;

		auto InstaKill = UAdultDragonTakeDamageKillComponent::Get(HitResult.Component.Owner);
		auto SmashResponse = UAdultDragonTailSmashModeResponseComponent::Get(HitResult.Component.Owner);
		auto FallingRockResponse = UAdultDragonTakeDamageDestructibleRocksComponent::Get(HitResult.Component.Owner);

		if (InstaKill != nullptr)
		{
			Params.ActivationType = EAdultDragonTakeDamageActivationType::Kill;
			Params.Impact = HitResult;
			return true;
		}

		if (FallingRockResponse != nullptr)
		{
			Params.ActivationType = EAdultDragonTakeDamageActivationType::DestroyRock;
			Params.DestructibleRockComp = FallingRockResponse;
			Params.Impact = HitResult;
			return true;
		}

		if (SmashResponse != nullptr)
		{
			bool bIsSmashing = Player.IsAnyCapabilityActive(AdultDragonCapabilityTags::AdultDragonSmashMode) || Player.IsAnyCapabilityActive(AdultDragonTailSmash::Tags::AdultDragonTailSmash);
			if (bIsSmashing)
				return false;
		}

		float HitDot = CameraComp.GetDesiredRotation().Vector().DotProduct(-HitResult.ImpactNormal);
		if (HitDot > 0.87)
		{
			Params.ActivationType = EAdultDragonTakeDamageActivationType::Kill;
			Params.Impact = HitResult;
			return true;
		}
		else
		{
			if (HealthComp.CanTakeDamage())
			{
				Params.ActivationType = EAdultDragonTakeDamageActivationType::Damage;
				Params.Impact = HitResult;
				return true;
			}
			if (MoveComp.Velocity.Size() < 5000.0)
			{
				Params.ActivationType = EAdultDragonTakeDamageActivationType::Kill;
				Params.Impact = HitResult;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAdultDragonTakeDamageActivationParams Params)
	{
		switch (Params.ActivationType)
		{
			case EAdultDragonTakeDamageActivationType::None:
			break;
			case EAdultDragonTakeDamageActivationType::Damage:
				HealthComp.DamagePlayer(0.2, DragonComp.ImpactDamageEffect, DragonComp.ImpactDeathEffect);
			break;
			case EAdultDragonTakeDamageActivationType::Kill:
				Player.KillPlayer(FPlayerDeathDamageParams(-Player.ActorForwardVector, 20.0), DragonComp.ImpactDeathEffect);
			break;
			case EAdultDragonTakeDamageActivationType::DestroyRock:
			{
				if (HasControl())
					Params.DestructibleRockComp.CrumbActivateStruckRock(Params.Impact.Component, Player, DragonComp.ImpactDamageEffect, DragonComp.ImpactDeathEffect);
			}
			break;
		}
	}
};