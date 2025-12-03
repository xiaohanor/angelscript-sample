event void FIslandRedBlueStickyGrenadeOnDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data);
event void FIslandRedBlueStickyGrenadeOnAttached(FIslandRedBlueStickGrenadeOnAttachedData Data);

struct FIslandRedBlueStickGrenadeOnDetonatedData
{
	/* The player who threw the grenade */
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	/* ExplosionStrengthAlpha will be 1 if the explosion is right at the response component and will approach zero as it approaches the max radius of the explosion */
	UPROPERTY()
	float ExplosionStrengthAlpha;

	/* The location of the grenade at the time of detonation */
	UPROPERTY()
	FVector ExplosionOrigin;

	/* The explosion radius of the grenade */
	UPROPERTY()
	float TotalExplosionRadius;

	/* How far away this response component is from the explosion origin */
	UPROPERTY()
	float DistanceToExplosion;

	UPROPERTY()
	int ExplosionIndex;
}

struct FIslandRedBlueStickGrenadeOnAttachedData
{
	/* The player who threw the grenade */
	UPROPERTY()
	AHazePlayerCharacter GrenadeOwner;

	/* The location of the grenade at the time of attach */
	UPROPERTY()
	FVector AttachedWorldLocation;

	/* The component the grenade just got attached to */
	UPROPERTY()
	UPrimitiveComponent AttachParent;

	/* The actor the grenade just got attached to */
	UPROPERTY()
	AActor AttachParentActor;
}

struct FIslandRedBlueStickyGrenadeBlocker
{
	TArray<FInstigator> Blockers;

	bool IsActive() const
	{
		return Blockers.Num() > 0;
	}
}

UCLASS(HideCategories = "Rendering Debug Activation Cooking Tags Lod Collision")
class UIslandRedBlueStickyGrenadeResponseComponent : USceneComponent
{
	access GrenadeAccess = private, AIslandRedBlueStickyGrenade;

	/* This will trigger when a sticky grenade is detonated close to this response component */
	UPROPERTY(Category = "Grenade Response Component")
	FIslandRedBlueStickyGrenadeOnDetonated OnDetonated;

	/* This will trigger when a grenade starts detonating, regardless of if bCanImpactMultipleTimesPerDetonation is true or not. */
	UPROPERTY(Category = "Grenade Response Component")
	FIslandRedBlueStickyGrenadeOnDetonated OnStartDetonating;

	/* This will trigger when a sticky grenade is attached to a component on the actor with this grenade response component */
	UPROPERTY(Category = "Grenade Response Component")
	FIslandRedBlueStickyGrenadeOnAttached OnAttached;

	/* If size is non-zero distance to the closest point on this shape will be used instead of to the world location of this component */
	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	FHazeShapeSettings Shape;

	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	bool bTriggerForRedPlayer = true;

	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	bool bTriggerForBluePlayer = true;

	// If true, the grenade needs to be attached to a component on the actor with this grenade response component in order to trigger.
	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	bool bTriggerRequiresGrenadeContact = false;

	// If true, will trigger OnDetonated every tick the response component is within an active explosion
	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	bool bCanImpactMultipleTimesPerDetonation = false;

	// These actors will be ignored when tracing to see if a grenade blast hits this response component (in additon to what is ignored by the player owned grenade container)
	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	TArray<AActor> IgnoreCollisionActors;

	// If true grenade will ignore all obstructions in the way of this response component when detonated
	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	bool bIgnoreDetonationTrace = false;

	UPROPERTY(EditAnywhere, Category = "Grenade Response Component")
	bool bAutomaticallySetActorControlSide = true;

	private TPerPlayer<FIslandRedBlueStickyGrenadeBlocker> DetonationBlockers;
	private TPerPlayer<int> LastExplosionIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio).ResponseComponents.AddUnique(this);
		LastExplosionIndex[0] = -1;
		LastExplosionIndex[1] = -1;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio).ResponseComponents.RemoveSingleSwap(this);
	}

	access:GrenadeAccess
	void TriggerDetonation(AHazePlayerCharacter GrenadeOwner, AIslandRedBlueStickyGrenade Grenade, FVector DetonateLocation, float DistanceToExplosion, float ExplosionRadius, int ExplosionIndex)
	{
		OnDetonation(GrenadeOwner, Grenade, DistanceToExplosion, ExplosionRadius, ExplosionIndex);

		FIslandRedBlueStickGrenadeOnDetonatedData EventData;
		EventData.GrenadeOwner = GrenadeOwner;
		EventData.ExplosionStrengthAlpha = 1.0 - Math::Saturate(DistanceToExplosion / ExplosionRadius);
		EventData.ExplosionOrigin = DetonateLocation;
		EventData.DistanceToExplosion = DistanceToExplosion;
		EventData.TotalExplosionRadius = ExplosionRadius;
		EventData.ExplosionIndex = ExplosionIndex;
		OnDetonated.Broadcast(EventData);

		if(ExplosionIndex != LastExplosionIndex[GrenadeOwner])
		{
			OnStartDetonating.Broadcast(EventData);
		}

		LastExplosionIndex[GrenadeOwner] = ExplosionIndex;
	}

	protected void OnDetonation(AHazePlayerCharacter GrenadeOwner, AIslandRedBlueStickyGrenade Grenade, float DistanceToExplosion, float ExplosionRadius, int ExplosionIndex) {}

	access:GrenadeAccess
	bool CanTriggerFor(AHazePlayerCharacter GrenadeOwner, const AIslandRedBlueStickyGrenade Grenade, float DistanceToExplosion, float ExplosionRadius)
	{
		if(!Grenade.HasControl())
			return false;

		if(DetonationBlockers[GrenadeOwner].IsActive())
			return false;

		if(IslandRedBlueWeapon::IsPlayerRed(GrenadeOwner))
		{
			if(!bTriggerForRedPlayer)
				return false;
		}
		else
		{
			if(!bTriggerForBluePlayer)
				return false;
		}

		if(bTriggerRequiresGrenadeContact)
		{
			if(Grenade.AttachParentActor != Owner)
				return false;

			return true;
		}

		if(DistanceToExplosion > ExplosionRadius)
			return false;

		if (bIgnoreDetonationTrace)
			return true; // No need to trace for obstructions 

		auto Settings = UIslandRedBlueStickyGrenadeSettings::GetSettings(GrenadeOwner);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseLine();
		Trace.IgnorePlayers();
		Trace.IgnoreActor(Grenade);
		Trace.IgnoreActor(Owner);

		auto OtherGrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(GrenadeOwner.OtherPlayer);
		if(OtherGrenadeUserComp != nullptr && OtherGrenadeUserComp.Grenade != nullptr)
			Trace.IgnoreActor(OtherGrenadeUserComp.Grenade);

		FVector Origin = Grenade.ActorLocation;
		TArray<FVector> Destinations;
		Destinations.Add(WorldLocation);

		if(!Shape.IsZeroSize())
		{
			Destinations.Add(Shape.GetClosestPointToPoint(WorldTransform, Grenade.ActorLocation));
		}

		TArray<AActor> IgnoreActors = IgnoreCollisionActors;
		IgnoreActors.Append(Grenade.GrenadeResponseContainer.IgnoreCollisionActors);
		TArray<UPrimitiveComponent> IgnoreComponents = Grenade.GrenadeResponseContainer.IgnoreCollisionComponents;

		GetRelevantIgnoreActors(IgnoreActors, Origin, Destinations);
		GetRelevantIgnoreComponents(IgnoreComponents, Origin, Destinations);

		Trace.IgnoreActors(IgnoreActors);
		Trace.IgnoreComponents(IgnoreComponents);

		for(int i = 0; i < Destinations.Num(); i++)
		{
			FHitResultArray Hits;
			if(!Grenade.ActorLocation.Equals(Destinations[i]))
				Hits = Trace.QueryTraceMulti(Origin, Destinations[i]);
			FHitResult ValidHit;

			if(HitResultArrayHasValidHit(Hits, GrenadeOwner, ValidHit))
			{
				if(Settings.bDebugGrenadeResponseComponents)
				{
					Debug::DrawDebugLine(Grenade.ActorLocation, ValidHit.ImpactPoint, FLinearColor::Red, 3.0, 1.0);
					Debug::DrawDebugString(ValidHit.ImpactPoint, "Blocked", FLinearColor::Red, 1.0);
				}
			}
			else
			{
				if(Settings.bDebugGrenadeResponseComponents)
				{
					Debug::DrawDebugLine(Grenade.ActorLocation, Destinations[i], FLinearColor::Green, 3.0, 1.0);
					Debug::DrawDebugString(WorldLocation, "Impact", FLinearColor::Green, 1.0);
				}

				return true;
			} 
		}

		return false;
	}

	void GetRelevantIgnoreActors(TArray<AActor>& ActorsToIgnore, FVector TraceStart, const TArray<FVector>& TraceEnds)
	{
		for(int i = ActorsToIgnore.Num() - 1; i >= 0; --i)
		{
			FVector Origin, Extent;
			ActorsToIgnore[i].GetActorBounds(true, Origin, Extent);
			FBox Box = FBox::BuildAABB(Origin, Extent);

			bool bIntersected = false;
			for(FVector TraceEnd : TraceEnds)
			{
				if(Math::LineBoxIntersection(Box, TraceStart, TraceEnd))
					bIntersected = true;
			}

			if(!bIntersected)
				ActorsToIgnore.RemoveAt(i);
		}
	}

	void GetRelevantIgnoreComponents(TArray<UPrimitiveComponent>& ComponentsToIgnore, FVector TraceStart, const TArray<FVector>& TraceEnds)
	{
		for(int i = ComponentsToIgnore.Num() - 1; i >= 0; --i)
		{
			FBox Box = ComponentsToIgnore[i].GetBounds().Box;

			bool bIntersected = false;
			for(FVector TraceEnd : TraceEnds)
			{
				if(Math::LineBoxIntersection(Box, TraceStart, TraceEnd))
					bIntersected = true;
			}

			if(!bIntersected)
				ComponentsToIgnore.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void BlockImpactForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		DetonationBlockers[Player].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void BlockImpactForColor(EIslandRedBlueWeaponType Color, FInstigator Instigator)
	{
		DetonationBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void UnblockImpactForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		DetonationBlockers[Player].Blockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void UnblockImpactForColor(EIslandRedBlueWeaponType Color, FInstigator Instigator)
	{
		DetonationBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].Blockers.RemoveSingleSwap(Instigator);
	}
	
	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	bool IsImpactBlockedForPlayer(AHazePlayerCharacter Player) const
	{
		return DetonationBlockers[Player].IsActive();
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	bool IsImpactBlockedForColor(EIslandRedBlueWeaponType Color) const
	{
		return DetonationBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].IsActive();
	}

	bool HitResultArrayHasValidHit(FHitResultArray Hits, AHazePlayerCharacter Player, FHitResult&out OutValidHit)
	{
		for(FHitResult Hit : Hits.BlockHits)
		{
			if(!CurrentHitIsValid(Hit, Player))
				continue;

			OutValidHit = Hit;
			return true;
		}

		return false;
	}

	bool CurrentHitIsValid(FHitResult Hit, AHazePlayerCharacter Player)
	{
		if(!Hit.bBlockingHit)
			return false;

		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		// We didn't hit a force field, the hit is valid!
		if(ForceField == nullptr)
			return true;

		// If we did hit a force field we want to trigger OnDetonated events through any force fields that the player owning this grenade can hit.
		if(ForceField.bAllowStickyGrenadesToDetonateThroughHoles && IslandRedBlueWeapon::PlayerCanHitShieldType(Player, ForceField.ForceFieldType))
			return false;

		return true;
	}
}

class UIslandRedBlueStickyGrenadeResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandRedBlueStickyGrenadeResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ResponseComp = Cast<UIslandRedBlueStickyGrenadeResponseComponent>(Component);

		if (!ResponseComp.Shape.IsZeroSize())
		{
			float MinXY = Math::Min(ResponseComp.WorldTransform.Scale3D.X, ResponseComp.WorldTransform.Scale3D.Y);
			
			switch (ResponseComp.Shape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						ResponseComp.WorldLocation,
						ResponseComp.Shape.BoxExtents * ResponseComp.WorldTransform.Scale3D,
						ResponseComp.ComponentQuat,
						FLinearColor::Green,
						2.0
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						ResponseComp.WorldLocation,
						ResponseComp.Shape.SphereRadius * Math::Min(MinXY, ResponseComp.WorldTransform.Scale3D.Z),
						FLinearColor::Green,
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						ResponseComp.WorldLocation,
						ResponseComp.WorldRotation,
						FLinearColor::Green,
						ResponseComp.Shape.CapsuleRadius * MinXY,
						ResponseComp.Shape.CapsuleHalfHeight * ResponseComp.WorldTransform.Scale3D.Z,
						16, 2.0
					);
				break;
				default:
					devError("Forgot to add case!");
			}
		}
	}
}