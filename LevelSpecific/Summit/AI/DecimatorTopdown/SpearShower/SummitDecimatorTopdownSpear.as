UCLASS(Abstract)
class ASummitDecimatorTopdownSpear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDecimatorTopdownSpearDecalCapability");

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent CapsuleComp;
	default CapsuleComp.bGenerateOverlapEvents = false;
	default CapsuleComp.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownBlobShadowComponent BlobShadowComp;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"EnemyIgnoreCharacters";
	default Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
	default Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacterAlternate, ECollisionResponse::ECR_Ignore);
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent ShadowDecal;

	USummitDecimatorTopdownSettings Settings;

	FVector SpawnLocation;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(this);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");

		UHazeTeam DecimatorTeam = HazeTeam::GetTeam(DecimatorTopdownTags::DecimatorTeamTag);
		for (auto Member : DecimatorTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;
			
			AHazeActor Decimator = DecimatorTeam.GetMembers().Last();
			Settings = USummitDecimatorTopdownSettings::GetSettings(Decimator);
		}		
	}

	UFUNCTION()
	void Reset()
	{	
		RemoveActorDisable(this);
		ActiveDuration = 0;
		bHasTriggeredExposed = false;
		bHasTriggeredSpawnedInGround = false;
		bHasHit = false;
		DetachFromActor();
		SetActorScale3D(FVector(1,1,1));
		RelativeOffset = FVector::ZeroVector;
		AccTelegraphOffset.SnapTo(0);
	}
	
	bool bFirstSpearInWave = false;
	bool bHasTriggeredSpawnedInGround = false;
	bool bHasTriggeredExposed = false;
	const float TelegraphTime = 1.0;
	float ActiveDuration;
	const float Period = 4;
	FVector RelativeOffset;
	AActor CurrentHitActor;
	FHazeAcceleratedFloat AccTelegraphOffset;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActiveDuration += DeltaSeconds;
		if (ActiveDuration < TelegraphTime)
		{
			// Just spawned
			if (!bHasTriggeredSpawnedInGround)
			{
				bHasTriggeredSpawnedInGround = true;
				USummitDecimatorSpearShowerEffectsHandler::Trigger_OnSpawnedInGround(this, FSummitDecimatorSpearShowerSpawnedInGroundParams(SpawnLocation + FVector(0,0,610)));
			}

			// Spring in a bit
			AccTelegraphOffset.SpringTo(70, 15, 0.5, DeltaSeconds); // Expose tip by 70 units
			FVector Offset = FVector(0, 0, AccTelegraphOffset.Value); // mesh.z * scale * half
			SetActorLocation(SpawnLocation + Offset);
			return;
		}
		else if (ActiveDuration > TelegraphTime + (3.14/Period) + 0.05)
		{
			ShadowDecal.SetHiddenInGame(true);
		}

		// Time to charge
		if (!bHasTriggeredExposed)
		{
			USummitDecimatorSpearShowerEffectsHandler::Trigger_OnExposed(this);
			bHasTriggeredExposed = true;

			if(bFirstSpearInWave)
			{
				AAISummitDecimatorTopdown Decimator = TListedActors<AAISummitDecimatorTopdown>().GetSingle();			
				USummitDecimatorTopdownEffectsHandler::Trigger_OnStartNewSpearShower(Decimator);
				bFirstSpearInWave = false;
			}			
		}

		FVector Offset = FVector(0, 0, Math::Sin((ActiveDuration-TelegraphTime) * Period)) * (350*5*.5); // mesh.z * scale * half

		if (!bHasHit)
		{			
			FHitResult Hit;
			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
			Trace.UseCapsuleShape(30, 100);
			Trace.IgnoreActor(this);
			Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + FVector::UpVector*300.0);			

			if (Hit.bBlockingHit)
			{
				SetActorLocation(Hit.ImpactPoint);
				Explode(Hit.Actor);
				RelativeOffset = Hit.Actor.ActorTransform.InverseTransformPosition(Hit.ImpactPoint);
				CurrentHitActor = Hit.Actor;
				//AttachToActor(Hit.Actor, AttachmentRule = EAttachmentRule::KeepWorld);
			}
			else
			{
				SetActorLocation(SpawnLocation + Offset);
			}
			
			if (ActiveDuration > (3.14/Period) + TelegraphTime + 0.1)
				Expire();
		}
		else
		{			
			SetActorLocation(CurrentHitActor.ActorLocation + RelativeOffset);
			SetActorScale3D(FVector(Math::Max(ActorScale3D.X - DeltaSeconds, 0), Math::Max(ActorScale3D.Y - DeltaSeconds, 0), Math::Max(ActorScale3D.Z - 0, 0)));
			
			if (ActiveDuration > StuckTime)
				Expire();
		}
	}


	UFUNCTION()
	private void Expire()
	{
		ShadowDecal.SetHiddenInGame(true);
		AddActorDisable(this);		
		RespawnComp.UnSpawn();
	}

	float StuckTime = 0.0;
	bool bHasHit = false;
	UFUNCTION()
	void Explode(AActor HitActor)
	{
		if (bHasHit)
			return;
		bHasHit = true;
		StuckTime = ActiveDuration + 3.0;
		// Trigger effect
		USummitDecimatorSpearShowerEffectsHandler::Trigger_OnExplode(this);		
		
		//Expire();

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HitActor);
		if (Player != nullptr)
			Player.DealTypedDamage(this, Settings.SpearExplosionDamage, EDamageEffectType::ObjectSharp, EDeathEffectType::ObjectSharp);
	}
};