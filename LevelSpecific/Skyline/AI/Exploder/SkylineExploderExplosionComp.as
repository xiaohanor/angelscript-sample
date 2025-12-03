class USkylineExploderExplosionComp : UActorComponent
{
	AAISkylineExploder Exploder;
	USkylineExploderSettings ExploderSettings;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Exploder = Cast<AAISkylineExploder>(Owner);
		ExploderSettings = USkylineExploderSettings::GetSettings(Exploder);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	void Explode()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		Trace.IgnoreActor(Owner);
		Trace.UseSphereShape(ExploderSettings.ProximityExplosionRadius);
		FOverlapResultArray OverlapResult = Trace.QueryOverlaps(Exploder.ActorCenterLocation);
		for (auto Overlap : OverlapResult.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;

			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Overlap.Actor);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(ExploderSettings.ProximityExplosionPlayerDamage, nullptr, nullptr);

			UBasicAIHealthComponent NPCHealthComp = UBasicAIHealthComponent::Get(Overlap.Actor);
			if (NPCHealthComp != nullptr)
				NPCHealthComp.TakeDamage(ExploderSettings.ProximityExplosionNpcDamage, EDamageType::Explosion, Exploder);
		}

		USkylineExploderEffectHandler::Trigger_OnProximityExplosion(Exploder);
		HealthComp.Die();
		Debug::DrawDebugSphere(Exploder.ActorCenterLocation, ExploderSettings.ProximityExplosionRadius, LineColor = FLinearColor::Red, Duration = 0.2);
	}
}