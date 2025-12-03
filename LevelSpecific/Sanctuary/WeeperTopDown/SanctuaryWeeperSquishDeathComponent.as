class USanctuaryWeeperSquishDeathComponent : UBoxComponent
{

	UFauxPhysicsTranslateComponent TranslateComp;
	UFauxPhysicsAxisRotateComponent RotateComp;
	UFauxPhysicsComponentBase PhysicsBase;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp = UFauxPhysicsTranslateComponent::Get(Owner);
		RotateComp = UFauxPhysicsAxisRotateComponent::Get(Owner);
		PhysicsBase = UFauxPhysicsComponentBase::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PhysicsBase == nullptr)
			return;

		if(PhysicsBase.IsSleeping())
			return;


		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseBoxShape(this);
		TraceSettings.IgnoreActor(Owner);

		FHitResult HitResult = TraceSettings.QueryTraceSingle(this.WorldLocation, this.WorldLocation + this.ForwardVector);

		if(HitResult.bBlockingHit)
		{
			auto Weeper = Cast<AAISanctuaryWeeper2D>(HitResult.Actor);

			if(Weeper != nullptr)
				Weeper.HealthComp.TakeDamage(Weeper.HealthComp.MaxHealth, EDamageType::MeleeBlunt, Game::Mio);
			
		}
	}


}