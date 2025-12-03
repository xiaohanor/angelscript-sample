UCLASS(Abstract)
class ASkylineGeckoOrb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SetCollisionProfileName(n"BlockAllDynamic");
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	UPROPERTY(EditAnywhere)
	float GrabbedDrag = 1.0;

	UPROPERTY(EditAnywhere)
	float ThrownDrag = 1.0;

	// Set to 0 for no gravity
	UPROPERTY(EditAnywhere)
	float Gravity = -980.0;

	UPROPERTY(EditAnywhere)
	float SlingSpeed = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bCanDamagePlayer;

	bool bGrabbed;
	bool bThrown;

	UPROPERTY(EditAnywhere, Category = "Damage")
	float Damage = 1.0;

	UPROPERTY(EditAnywhere, Category = "Damage")
	EDamageType DamageType = EDamageType::Default;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem HitEffect;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bUseRadialDamage;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseRadialDamage", EditConditionHides), Category = "Damage")
	float RadialDamage = 0.5;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseRadialDamage", EditConditionHides), Category = "Damage")
	float RadialDamageRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "DebugLine")
	bool bDrawDebugLine;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Setup the resolver
		{	
			UMovementResolverSettings::SetMaxRedirectIterations(this, 3, this, EHazeSettingsPriority::Defaults);
			UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);
		}

		// Everything is sliding
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);
		}

		Movement = MovementComponent.SetupSweepingMovementData();

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if (!bGrabbed && !bThrown) 
			return;
		
		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			FVector Acceleration = Force * 1.0
								- MovementComponent.Velocity * (bThrown ? ThrownDrag : GrabbedDrag)
								+ FVector::UpVector * Gravity * (bThrown ? 1.0 : 0.0);
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			MovementComponent.ApplyMove(Movement);
		}		

		// Some temp added rotation
		AddActorLocalRotation(FRotator(10.0, 20.0, 10.0) * 6.0 * DeltaSeconds);	

		if(MovementComponent.HasAnyValidBlockingContacts() && bThrown)
		{
			TArray<FHitResult> HitResults;
			if(MovementComponent.HasWallContact())
				HitResults.Add(MovementComponent.WallContact.ConvertToHitResult());

			if(MovementComponent.HasGroundContact())
				HitResults.Add(MovementComponent.GroundContact.ConvertToHitResult());
			
			if(MovementComponent.HasCeilingContact())
				HitResults.Add(MovementComponent.CeilingContact.ConvertToHitResult());

			for(auto HitResult : HitResults)
			{
				AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(HitResult.Actor);
				if(PlayerTarget == nullptr)
					Damage::AITakeDamage(HitResult.Actor, Damage, Game::Zoe, EDamageType::Explosion);
				else if (bCanDamagePlayer)
					PlayerTarget.DamagePlayerHealth(Damage);
			}

			if(bUseRadialDamage)
			{
				Damage::PlayerRadialDamage(ActorLocation, RadialDamageRadius, RadialDamage);
				Damage::AIRadialDamageToTeam(ActorLocation, RadialDamageRadius, RadialDamage, Game::Zoe, AITeams::Default);
			}

			Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorLocation, ActorRotation);
			DestroyActor();
		}
	}

	UFUNCTION()
	void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bGrabbed = true;
	}

	UFUNCTION()
	void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		if(bDrawDebugLine)
			Debug::DrawDebugLine(ActorLocation, ActorLocation + (Impulse.GetSafeNormal() * 2000.0), FLinearColor::Green, 10.0, 2.0);
		bThrown = true;
		GravityWhipTargetComponent.Disable(this);
		SetActorVelocity(Impulse.GetSafeNormal() * SlingSpeed);
	}

}