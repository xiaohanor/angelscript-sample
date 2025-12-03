class UMoonMarketBouncyBallFauxAxisRotatorResponseComponent : UFauxPhysicsAxisRotateComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UMoonMarketBouncyBallResponseComponent::GetOrCreate(Owner).OnHitByBallEvent.AddUFunction(this, n"OnHit");
		UFireworksResponseComponent::GetOrCreate(Owner).OnFireWorksImpact.AddUFunction(this, n"OnHitByFirework");
	}

	UFUNCTION()
	private void OnHitByFirework(FMoonMarketFireworkImpactData Data)
	{
		FVector Dir = (Data.ImpactPoint - Data.Rocket.ActorLocation).GetSafeNormal();
		float ClampedDistance = Math::Saturate((Data.ImpactPoint - Data.Rocket.ActorLocation).Size() / 600);
		
		ApplyImpulse(Data.ImpactPoint, Dir * (1 - ClampedDistance) * 3000);
	}

	UFUNCTION()
	private void OnHit(FMoonMarketBouncyBallHitData Data)
	{
		ApplyImpulse(Data.ImpactPoint, Data.ImpactVelocity * 1);
		//Debug::DrawDebugDirectionArrow(Data.ImpactPoint, Data.ImpactVelocity.GetReflectionVector(Data.ImpactNormal), Length = 200, ArrowSize = 200, Duration = 2);
		//Data.Ball.AddMovementImpulse(Data.ImpactVelocity.GetReflectionVector(Data.ImpactNormal) * Data.ImpactVelocity.Size() * 0.5);
	}
};