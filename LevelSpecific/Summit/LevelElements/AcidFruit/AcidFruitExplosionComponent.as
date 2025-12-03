class UAcidFruitExplosionComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float MaxHitCount = 20;

	float HitCount;
	float ExplosionForce = 50000000.0;

	UPROPERTY(EditAnywhere)
	float ExplosionRadius = 800.0;
	bool bHasExploded;


	float GetAcidPercentage()
	{
		return HitCount / MaxHitCount; 
	}

	bool CanExplode()
	{
		if(HitCount >= MaxHitCount)
			return true;

		return false;
	}
	
	void AddHitCount()
	{
		if(HitCount >= MaxHitCount)
			return;
		
		HitCount++;
	}

	void OnExplode()
	{
		if(bHasExploded)
			return;
		bHasExploded = true;

		FHazeTraceDebugSettings TraceSettings = TraceDebug::MakeDuration(5.0);
		TraceSettings.TraceColor = FLinearColor::Red;
		TraceSettings.Thickness = 10.0;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Owner);
		Trace.UseSphereShape(ExplosionRadius);
		Trace.DebugDraw(TraceSettings);
		FHitResultArray Hits = Trace.QueryTraceMulti(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorForwardVector * 0.1);

		for(FHitResult Hit : Hits)
		{
			if(!Hit.bBlockingHit)
				continue;
			
			FVector Direction = (Hit.Actor.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			FVector Impulse = Direction * ExplosionForce;

			if(Hit.GetComponent().IsSimulatingPhysics())
				Hit.GetComponent().AddImpulse(Impulse);

			UAcidFruitResponseComponent ResponseComp = UAcidFruitResponseComponent::Get(Hit.Actor);
			if(ResponseComp == nullptr)
				continue;

			ResponseComp.OnAcidFruitExplosion.Broadcast();

		}


		
	}
}