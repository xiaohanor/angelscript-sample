event void FOnIslandProjectileHit(FVector HitLocation, UIslandProjectileComponent ProjectileComp);
event void FOnIslandLaserHit(FVector HitLocation, float DamagePerSecond, float DamageInterval);

class UIslandProjectileResponseComponent : UActorComponent
{
	UPROPERTY()
    FOnIslandProjectileHit OnProjectileHit;

	UPROPERTY()
	FOnIslandLaserHit OnLaserHit;
}

class UIslandProjectileComponent : UBasicAIProjectileComponent
{
	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false) override
	{
		FVector OwnLoc = Owner.ActorLocation;
		
		Velocity -= UpVector * Gravity * DeltaTime;
		Velocity -= Velocity * Friction * DeltaTime;
		FVector Delta = Velocity * DeltaTime;
		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(TraceType);
			Trace.UseLine();
			Trace.IgnoreActors(AdditionalIgnoreActors);

			if (Launcher != nullptr)
			{	
				Trace.IgnoreActor(Launcher, bIgnoreDescendants);

				if (bIgnoreLauncherAttachParents)
				{
					AActor AttachParent = Launcher.AttachParentActor;
					while (AttachParent != nullptr)
					{
						Trace.IgnoreActor(AttachParent);
						AttachParent = AttachParent.AttachParentActor;
					}				
				}
			}
			OutHit = Trace.QueryTraceSingle(OwnLoc, OwnLoc + Delta);

			if (OutHit.bBlockingHit && !IslandForceField::HasHitForceFieldObstacleHole(OutHit))
				return OutHit.ImpactPoint;		
		}

		return OwnLoc + Delta;
	}

	void Impact(FHitResult Hit) override
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(HazeOwner, Data);
		Expire();		
	}
}