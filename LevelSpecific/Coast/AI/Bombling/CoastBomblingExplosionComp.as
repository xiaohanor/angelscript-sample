class UCoastBomblingExplosionComp : UActorComponent
{
	AAICoastBombling Exploder;
	ACoastTrainCart TrainCart;
	UCoastBomblingSettings Settings;
	UBasicAIHealthComponent HealthComp;
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ExplosionCameraShake;
	UPROPERTY()
	UForceFeedbackEffect ExplosionForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Exploder = Cast<AAICoastBombling>(Owner);
		Settings = UCoastBomblingSettings::GetSettings(Exploder);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else
			TrainCart = nullptr;
	}

	void Explode()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		Trace.IgnoreActor(Owner);
		Trace.UseSphereShape(Settings.ProximityExplosionRadius);

		FOverlapResultArray OverlapResult = Trace.QueryOverlaps(Exploder.ActorCenterLocation);
		for (auto Overlap : OverlapResult.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player != nullptr)
				DamagePlayer(Player);

			UBasicAIHealthComponent NPCHealthComp = UBasicAIHealthComponent::Get(Overlap.Actor);
			if (NPCHealthComp != nullptr)
				NPCHealthComp.TakeDamage(Settings.ProximityExplosionNpcDamage, EDamageType::Explosion, Exploder);
		}

		if(TrainCart != nullptr)
		{
			// Impact the train cart's suspension from the explosion
			FVector SuspensionForce = FVector(0.0, 0.0, -400.0);
			TrainCart.AddSuspensionImpulse(SuspensionForce);
		}

		AActor AttachActor = nullptr;
		if(RespawnComp.Spawner != nullptr)
			AttachActor = RespawnComp.Spawner.AttachParentActor;

		if(AttachActor == nullptr)
			AttachActor = Exploder;
		UCoastBomblingEffectHandler::Trigger_OnProximityExplosion(Exploder, FCoastBomblingOnProximityExplosionData(AttachActor));
		HealthComp.Die();
		//Debug::DrawDebugSphere(Exploder.ActorCenterLocation, Settings.ProximityExplosionRadius, LineColor = FLinearColor::Red, Duration = 0.2);
	}

	private void DamagePlayer(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return;

		Player.DamagePlayerHealth(Settings.ProximityExplosionPlayerDamage);

		if(TrainCart == nullptr)
			return;

		UTrainPlayerLaunchOffComponent LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);

		// Launch relative to train, but switch side sign depending on player position
		FVector LaunchForceLocal = Settings.ProximityExplosionLaunchForce;
		if (TrainCart.ActorRightVector.DotProduct(Player.ActorLocation - TrainCart.ActorLocation) < 0.0)
			LaunchForceLocal.Y *= -1.0;

		FTrainPlayerLaunchParams Launch;
		Launch.LaunchFromCart = TrainCart;
		Launch.ForceDuration = Settings.ProximityExplosionLaunchPushDuration;
		Launch.FloatDuration = Settings.ProximityExplosionLaunchFloatDuration;
		Launch.PointOfInterestDuration = Settings.ProximityExplosionLaunchPointOfInterestDuration;
		Launch.Force = TrainCart.ActorTransform.TransformVectorNoScale(LaunchForceLocal);
		LaunchComp.TryLaunch(Launch);

		Player.PlayCameraShake(ExplosionCameraShake, this);
		Player.PlayForceFeedback(ExplosionForceFeedback, false, false, this);
	}
}
