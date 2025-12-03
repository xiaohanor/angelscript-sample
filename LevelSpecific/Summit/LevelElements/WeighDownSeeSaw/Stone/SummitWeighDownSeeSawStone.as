asset SummitWeighDownSeeSawStoneGravitySettings of UMovementGravitySettings
{
	GravityAmount = 4000.0;
}

class ASummitWeighDownSeeSawStone : AHazeActor
{
	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StoneMesh;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent ActorSyncComp;
	default ActorSyncComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWeighDownSeeSawStoneMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWeighDownSeeSawStoneRotationCapability");

	UPROPERTY(DefaultComponent, Attach = StoneMesh)
	UTeenDragonTailAttackResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedAngularVelocityComp;
	default SyncedAngularVelocityComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitWeighDownSeeSaw SeeSaw;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> ActorsToIgnore;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float HorizontalSpeed = 1000.0;

	FVector AngularVelocity;

	bool bHasBeenHit = false;
	bool bHasHitSeeSaw = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		ApplySettings(SummitWeighDownSeeSawStoneGravitySettings, this);

		MoveComp.AddMovementIgnoresActors(this, ActorsToIgnore);

		for(auto Player : Game::Players)
		{
			MoveComp.AddMovementIgnoresActor(this, Player);
		}
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		FVector TargetLocation = SeeSaw.TargetRoot.WorldLocation;
		FVector DirToTarget = (TargetLocation - ActorLocation).GetSafeNormal();
		FVector FlatDir = DirToTarget.ConstrainToPlane(FVector::UpVector);

		KillPlayerInFront(FlatDir);
		MoveComp.AddPendingImpulse(FlatDir * HorizontalSpeed);
		
		bHasBeenHit = true;
	}

	void KillPlayerInFront(FVector FrontDir)
	{
		FHazeTraceSettings PlayerTrace;
		PlayerTrace.TraceWithObjectType(EObjectTypeQuery::PlayerCharacter);
		PlayerTrace.UseSphereShape(SphereComp);

		FVector SphereGroundDownwardsOffset = -ActorUpVector * SphereComp.SphereRadius * 0.5;
		FVector Start = ActorLocation + SphereGroundDownwardsOffset;
		FVector End = Start + (FrontDir * 600);
		auto Hits = PlayerTrace.QueryTraceMulti(Start, End);

		TEMPORAL_LOG(this)
			.HitResults("Player Trace", Hits, Start, End, FHazeTraceShape::MakeSphere(SphereComp.SphereRadius * 0.5))
		;

		for(auto Hit : Hits)
		{
			if(!Hit.IsValidBlockingHit())
				continue;

			if(Hit.bBlockingHit)
			{
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(Player != nullptr)
					Player.KillPlayer(); 
			}
		}
	}
};