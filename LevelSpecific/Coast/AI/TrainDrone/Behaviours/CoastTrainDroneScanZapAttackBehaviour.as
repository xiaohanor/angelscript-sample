class UCoastTrainDroneScanZapAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	AHazePlayerCharacter PlayerTarget;

	UBasicAIHealthComponent HealthComp;
	UCoastTrainDroneSettings Settings;
	ACoastTrainCart TrainCart;
	UBasicAIProjectileLauncherComponent Weapon;
	FVector AttackLocalLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UCoastTrainDroneSettings::GetSettings(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		OnRespawn(); // In case owner is not spawned by spawner
	}

	UFUNCTION()
	private void OnRespawn()
	{
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);
		else
			TrainCart = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Attack as soon as we have a target
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (ActiveDuration > Settings.ScanAttackTelegraphDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Telegraph for a while, then let loose!
		AnimComp.RequestFeature(LocomotionFeatureAITags::Taunt, SubTagAITaunts::Telegraph, EBasicBehaviourPriority::Medium, this, Settings.ScanAttackTelegraphDuration);
		// FVector AttackLoc = Math::ProjectPositionOnInfiniteLine(TrainCart.ActorLocation, TrainCart.ActorForwardVector, Weapon.LaunchLocation);
		FVector AttackLoc = TargetComp.Target.ActorLocation;
		AttackLocalLoc = TrainCart.ActorTransform.InverseTransformPosition(AttackLoc);
		UCoastTrainDroneEffectHandler::Trigger_OnTelegraph(Owner, FTrainDroneAttackParams(Weapon, TrainCart, AttackLocalLoc));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UCoastTrainDroneEffectHandler::Trigger_OnStopTelegraphing(Owner);

		// Forget target, we need to find them again.
		TargetComp.Target = nullptr;

		if (ActiveDuration > Settings.ScanAttackTelegraphDuration)
			Cooldown.Set(Settings.ScanAttackCooldownTime);

		if (!HealthComp.IsDead() && !IsBlocked())
		{
			// Unleash the fury! (Crumb synced since in OnDeactivated, damage and launch is synced separately)
			UCoastTrainDroneEffectHandler::Trigger_OnAttack(Owner, FTrainDroneAttackParams(Weapon, TrainCart, AttackLocalLoc));

			FVector Epicenter = TrainCart.ActorTransform.TransformPosition(AttackLocalLoc);
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;

				float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorLocation, Epicenter, Settings.ScanAttackRadius);
				if (DamageFactor == 0.0)
					continue; // Miss!
				
				Player.DamagePlayerHealth(Settings.ScanAttackDamage * DamageFactor);

				UTrainPlayerLaunchOffComponent LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);

				// Launch relative to train, but switch side sign depending on player position
				FVector LaunchForceLocal = Settings.ScanAttackLaunchForce;
				if (TrainCart.ActorRightVector.DotProduct(Player.ActorLocation - TrainCart.ActorLocation) < 0.0)
					LaunchForceLocal.Y *= -1.0;
				
				FTrainPlayerLaunchParams Launch;
				Launch.LaunchFromCart = TrainCart;
				Launch.ForceDuration = Settings.ScanAttackLaunchPushDuration;
				Launch.FloatDuration = Settings.ScanAttackLaunchFloatDuration;
				Launch.PointOfInterestDuration = Settings.ScanAttackLaunchPointOfInterestDuration;
				Launch.Force = TrainCart.ActorTransform.TransformVectorNoScale(LaunchForceLocal);
				LaunchComp.TryLaunch(Launch);
			}

			// Impact the train cart's suspension from the explosion
			FVector SuspensionForce = FVector(0.0, 0.0, -400.0);
			TrainCart.AddSuspensionImpulse(SuspensionForce);
		}
	}
}


