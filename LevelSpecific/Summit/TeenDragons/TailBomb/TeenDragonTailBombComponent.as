event void FOnTailBombIgnited();

class UTeenDragonTailBombComponent : UHazeSphereCollisionComponent
{
	UPROPERTY(Category = "Events")
	FOnTailBombIgnited OnTailBombIgnited;

	// How far will we pick up 'TeenDragonTailBombImpactResonseComponent'
	UPROPERTY(Category = "Settings")
	float ExplosionRadius = 1000;

	default SetSphereRadius(80, false);
	default SetCollisionProfileName(n"NoCollision", false);
	default SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);

	UPROPERTY(Category = "Settings")
	FVector ThrowAmount = FVector(5000, 0, 1000);

	UPROPERTY(Category = "Settings")
	float GravityAmount = 5000;

	// If true, the bomb can be ignited while picked up
	UPROPERTY(Category = "Settings")
	bool bCanIgniteIfPickedUp = true;

	// How long until the bomb explodes after it has been picked up
	UPROPERTY(Category = "Settings")
	float ExplosionDelay = 5;

	private AHazeActor HazeOwner;
	private FVector ActiveThrowVelocity = FVector::ZeroVector;
	private bool bIsPickedUp = false;
	private bool bUpdateMovement = false;
	private bool bAcidHit;
	private UTeenDragonTailBombPickupComponent InteractionComp;
	private FRotator ThrowOrientation = FRotator::ZeroRotator;
	private float TimeLeftToExplode = -1;
	private TArray<UPrimitiveComponent> BlockedCollisionComps;

	TArray<FInstigator> Disablers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		InteractionComp = UTeenDragonTailBombPickupComponent::Get(Owner);
		auto AcidResponse = UAcidResponseComponent::Get(Owner);
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	void Throw(FVector Forward, FVector Force)
	{
		ThrowOrientation = Forward.ToOrientationRotator();
		Owner.SetActorRotation(ThrowOrientation);
		ActiveThrowVelocity = ThrowOrientation.RotateVector(Force);
		bIsPickedUp = false;
		bUpdateMovement = true;
	}

	void PickUp()
	{
		bIsPickedUp = true;
		ActiveThrowVelocity = FVector::ZeroVector;
		InteractionComp.Disable(this);

		TArray<UPrimitiveComponent> CollisionComps;
		Owner.GetComponentsByClass(CollisionComps);
		for(auto It : CollisionComps)
		{
			if(It == this)
				continue;
			
			BlockedCollisionComps.Add(It);
			It.AddComponentCollisionBlocker(this);
		}
	}

	void Drop(FVector DragonForward)
	{
		Throw(DragonForward, FVector::UpVector * 800);
	}

	bool HasBeenThrown() const
	{
		return !ActiveThrowVelocity.IsNearlyZero();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAcidHit(FAcidHit AcidHit)
	{
		if(bAcidHit)
			return;

		if(!bIsPickedUp || bCanIgniteIfPickedUp)
		{
			TimeLeftToExplode = ExplosionDelay;
			bAcidHit = true;
			OnTailBombIgnited.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Disablers.Num() > 0)
			return;

		if(bUpdateMovement)
		{
			const FVector PrevLocation = Owner.GetActorLocation();
			FVector NewLocation = PrevLocation;

			const FVector Gravity = FVector::UpVector * -GravityAmount * (DeltaSeconds * 0.5);
			ActiveThrowVelocity += Gravity;
			NewLocation += ActiveThrowVelocity * DeltaSeconds;
	
			auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceZoe);
			Trace.UseSphereShape(GetScaledSphereRadius());
			Trace.IgnoreActor(Owner);

			auto Hit = Trace.QueryTraceSingle(PrevLocation, NewLocation);
			if(Hit.IsValidBlockingHit())
			{
				// Force the explosion if we hit something
				if(TimeLeftToExplode > 0)
				{
					TimeLeftToExplode = 0;
					RunExplosion();
				}
				
				// Stop at the impact
				ActiveThrowVelocity = FVector::ZeroVector;
				const float ImpactAngle = FVector::UpVector.GetAngleDegreesTo(Hit.ImpactNormal);

				// GroundImpact
				if(ImpactAngle < 60)
				{
					Owner.SetActorLocation(Hit.Location);
					bUpdateMovement = false;
					InteractionComp.Enable(this);
				}
				else
				{
					// Stop at the impact with some offset so we dont end up inside
					Owner.SetActorLocation(Hit.Location + Hit.ImpactNormal);
				}
			}
			else
			{
				Owner.SetActorLocation(NewLocation);
			}
		}

		if(!bUpdateMovement && TimeLeftToExplode > 0)
		{
			TimeLeftToExplode -= DeltaSeconds;
			if(TimeLeftToExplode <= 0)
			{
				RunExplosion();
			}
			else
			{
				float Alpha = 1 - (TimeLeftToExplode / ExplosionDelay);
				Alpha = Math::Pow(Alpha, 3);
				float Time = Time::GameTimeSeconds * Math::Lerp(0.1, 30, Alpha);
				Owner.SetActorScale3D( Math::Lerp(FVector(0.9), FVector(1.25), (Math::Sin(Time) + 1) * 0.5));
			}
		}

		// Make sure we are not overlapping any of the player when we turn on the collision
		if(!bIsPickedUp && !bUpdateMovement && BlockedCollisionComps.Num() > 0)
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseSphereShape(GetScaledSphereRadius() - 1);
			Trace.IgnoreActor(Owner);
			auto Overlaps = Trace.QueryOverlaps(WorldLocation);

			if(!Overlaps.HasBlockHit())
			{
				for(auto It : BlockedCollisionComps)
					It.RemoveComponentCollisionBlocker(this);

				BlockedCollisionComps.Reset();
			}
		}

		//Owner.TemporalLogAllDefaultDisableLogic();
	}

	void RunExplosion()
	{
		auto Player = Game::Zoe;

		// Call the effect handler for the explosion
		{
			FTeenDragonTailBombExplodeVFXData Data;
			Data.Location = WorldLocation;
			UTeenDragonTailBombVFXHandler::Trigger_OnExplode(Player, Data);
		}
		
		auto CarrierComp = UTeenDragonTailBombCarrierComponent::Get(Player);
		for(auto It : CarrierComp.ImpactResponeseComponents)
		{
			if(It.WorldLocation.DistSquared(WorldLocation) < Math::Square(ExplosionRadius))
			{
				It.TriggerExplosionResponse(HazeOwner);
			}
		}
		Owner.DestroyActor();
	}

	//Probs replace these with adding and removing disablers for the bomb
	void DisableBomb(FInstigator Disabler)
	{
		Disablers.AddUnique(Disabler);
		InteractionComp.Disable(this);
	}

	void EnableBomb(FInstigator Disabler)
	{
		if (Disablers.Contains(Disabler))
			Disablers.Remove(Disabler);
		
		if (Disablers.Num() == 0)
		{
			InteractionComp.Enable(this);
			bUpdateMovement = true;
		}
	}
}

#if EDITOR
class UTeenDragonTailBombComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTeenDragonTailBombComponent;
	
    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto BombComp = Cast<UTeenDragonTailBombComponent>(Component);
        if (BombComp == nullptr)
            return;

		DrawWireSphere(BombComp.WorldLocation, BombComp.ExplosionRadius, FLinearColor::Red, 2);	
    }
}
#endif