UCLASS(Abstract)
class ADentistDispensedCandy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionProfileName = CollisionProfile::NoCollision;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif
	
	UPROPERTY(EditAnywhere, Category = "Dispensed Candy")
	float Radius = 50;

	UPROPERTY(EditAnywhere, Category = "Dispensed Candy")
	float ForwardSpinSpeed = 0.4;

	UPROPERTY(EditAnywhere, Category = "Dispensed Candy")
	float SideSpinSpeed = 1.0;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float PlayerImpactAwayImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	bool bPlayerImpactNeverLaunchDownwards = true;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float PlayerImpactVerticalImpulse = 1500;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	FDentistToothApplyRagdollSettings PlayerImpactRagdollSettings;

	FTraversalTrajectory Trajectory;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector NewLocation = Trajectory.GetLocation(GameTimeSinceCreation);

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			SweepForPlayer(Player, ActorLocation, NewLocation);
		}

		float ChocolateWaterHeight = Dentist::GetChocolateWaterHeight(NewLocation);
		if(NewLocation.Z < ChocolateWaterHeight)
		{
			FVector Intersection = Math::LinePlaneIntersection(
				ActorLocation,
				NewLocation,
				FVector(NewLocation.X, NewLocation.Y, ChocolateWaterHeight),
				FVector::UpVector
			);

			SetActorLocation(Intersection);

			OnHitWater();
			return;
		}

		SetActorLocation(NewLocation);
		SetActorVelocity(Trajectory.GetVelocity(GameTimeSinceCreation));

		const FVector AngularVelocity = ActorVelocity.CrossProduct(FVector::UpVector);

		float RotationSpeed = -AngularVelocity.Size() / Radius;
		FQuat Roll = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * ForwardSpinSpeed * DeltaSeconds);
		AddActorWorldRotation(Roll);

		AddActorWorldRotation(FQuat(ActorUpVector, SideSpinSpeed * DeltaSeconds));
	}

	private void SweepForPlayer(AHazePlayerCharacter Player, FVector Start, FVector End)
	{
		if(Start.Equals(End))
			return;

		FHazeTraceSettings TraceSettings = Trace::InitAgainstComponent(Player.CapsuleComponent);
		TraceSettings.UseSphereShape(Radius);

		FHitResult Hit = TraceSettings.QueryTraceComponent(Start, End);
		if(Hit.bBlockingHit && Hit.Actor == Player)
		{
			auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
			if(ResponseComp == nullptr)
				return;

			FVector ImpulseDirection = ActorVelocity;

			if(bPlayerImpactNeverLaunchDownwards)
			{
				if(ImpulseDirection.Z < 0)
					ImpulseDirection.Z = 0;
			}

			ImpulseDirection.Normalize();

			const FVector Impulse = (ImpulseDirection * PlayerImpactAwayImpulse) + (FVector::UpVector * PlayerImpactVerticalImpulse);

			ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, PlayerImpactRagdollSettings);

			UDentistDispensedCandyEventHandler::Trigger_OnHitPlayer(this);
		}
	}

	private void OnHitWater()
	{
		FDentistDispensedCandyOnHitWaterEventData EventData;
		EventData.Location = ActorLocation;
		UDentistDispensedCandyEventHandler::Trigger_OnHitWater(this, EventData);

		DestroyActor();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, Radius);
	}
#endif
};