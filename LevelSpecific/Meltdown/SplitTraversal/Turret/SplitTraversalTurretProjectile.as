UCLASS(Abstract)
class ASplitTraversalTurretProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ScifiRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent FantasyRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent FishMeshComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem Explosion;

	float TargetDepth;
	FVector Velocity;
	bool bBounced = false;
	bool bTransferred = false;

	float ScifiGravity;
	float FantasyGravity;
	float TransitionVelocityMultiplier;
	bool bLoseDownwardVelocityOnTransition;

	ASplitTraversalTurret Turret;
	EHazeWorldLinkLevel PrevVisibleSplit;

	float MaxDuration = 10.0;
	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		PrevVisibleSplit = Manager.GetSplitForLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		Timer += DeltaSeconds;

		EHazeWorldLinkLevel ActorSplit = Manager.GetSplitForLocation(ActorLocation);

		EHazeWorldLinkLevel VisibleSplit = Manager.GetVisibleSplitForLocationOnScreen(ActorLocation);
		if (bBounced || bTransferred)
			VisibleSplit = PrevVisibleSplit;

		FVector PrevVelocity = Velocity;
		if (VisibleSplit == EHazeWorldLinkLevel::SciFi)
			Velocity += FVector::DownVector * ScifiGravity * DeltaSeconds;
		else
			Velocity += FVector::DownVector * FantasyGravity * DeltaSeconds;

		FVector PrevVisibleLocation;
		if (VisibleSplit == EHazeWorldLinkLevel::SciFi)
			PrevVisibleLocation = ScifiRoot.WorldLocation;
		else
			PrevVisibleLocation = FantasyRoot.WorldLocation;

		if (VisibleSplit != PrevVisibleSplit)
		{
			AHazePlayerCharacter SourcePlayer = Manager.GetPlayerForSplit(ActorSplit);
			AHazePlayerCharacter TargetPlayer = Manager.GetPlayerForSplit(VisibleSplit);

			Velocity = SourcePlayer.ViewRotation.UnrotateVector(Velocity);
			Velocity = TargetPlayer.ViewRotation.RotateVector(Velocity);

			Velocity.X *= TransitionVelocityMultiplier;
			Velocity.Y *= TransitionVelocityMultiplier;
			if (bLoseDownwardVelocityOnTransition || Velocity.Z > 0)
				Velocity.Z *= TransitionVelocityMultiplier;

			bTransferred = true;

			ScifiRoot.SetHiddenInGame(true, true);
		}

		FVector NewVisibleLocation = PrevVisibleLocation + Velocity * DeltaSeconds;
		FHazeTraceSettings Trace;
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(Turret);
		Trace.UseLine();
		Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);

		FHitResult Hit = Trace.QueryTraceSingle(PrevVisibleLocation, NewVisibleLocation);
		if (VisibleSplit != PrevVisibleSplit && (Hit.bStartPenetrating || Hit.bBlockingHit))
		{
			bBounced = true;

			AHazePlayerCharacter SourcePlayer = Manager.GetPlayerForSplit(VisibleSplit);
			AHazePlayerCharacter TargetPlayer = Manager.GetPlayerForSplit(PrevVisibleSplit);

			Velocity = PrevVelocity;
			Velocity = Math::GetReflectionVector(Velocity,
				-Manager.GetPlayerForSplit(PrevVisibleSplit).ViewRotation.RightVector);

			VisibleSplit = PrevVisibleSplit;
			ScifiRoot.SetHiddenInGame(false, true);
		}
		else if (Hit.bStartPenetrating)
		{
			auto ResponseComp = USplitTraversalTurretProjectileResponseComponent::Get(Hit.Actor);
			if (ResponseComp != nullptr || VisibleSplit == EHazeWorldLinkLevel::SciFi)
				Explode(Hit.Actor, Hit.TraceStart);
		}
		else if (Hit.bBlockingHit)
		{
			auto ResponseComp = USplitTraversalTurretProjectileResponseComponent::Get(Hit.Actor);
			if (ResponseComp != nullptr || VisibleSplit == EHazeWorldLinkLevel::SciFi)
			{
				Explode(Hit.Actor, Hit.ImpactPoint);
			}
			else
			{
				FishMeshComp.SetSimulatePhysics(true);
				FantasyRoot.SetHiddenInGame(true, true);
				FishMeshComp.SetHiddenInGame(false);
				//Velocity = Math::GetReflectionVector(Velocity, Hit.ImpactNormal);
			}
		}
		else
		{
			ActorLocation = NewVisibleLocation;
			ActorRotation = Velocity.Rotation();
		}

		if (Timer >= MaxDuration)
			Explode(nullptr, FishMeshComp.WorldLocation);

		ActorSplit = Manager.GetSplitForLocation(ActorLocation);
		// ScifiRoot.WorldLocation = Manager.ConvertPositionBasedOnScreenSpaceMaintainDepth(
		// 	ActorLocation, ActorSplit, EHazeWorldLinkLevel::SciFi
		// );
		// FantasyRoot.WorldLocation = Manager.ConvertPositionBasedOnScreenSpaceMaintainDepth(
		// 	ActorLocation, ActorSplit, EHazeWorldLinkLevel::Fantasy
		// );
		ScifiRoot.WorldLocation = Manager.ConvertPositionBasedOnScreenSpaceForceDepth(
			ActorLocation, ActorSplit, EHazeWorldLinkLevel::SciFi, TargetDepth
		);
		FantasyRoot.WorldLocation = Manager.ConvertPositionBasedOnScreenSpaceForceDepth(
			ActorLocation, ActorSplit, EHazeWorldLinkLevel::Fantasy, TargetDepth
		);

		PrevVisibleSplit = VisibleSplit;
	}

	bool HasObstruction(FVector Point)
	{
		FHazeTraceSettings Trace;
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(Turret);
		Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseSphereShape(100.0 + Velocity.Size());

		auto Overlaps = Trace.QueryOverlaps(Point);
		for (auto Hit : Overlaps)
		{
			if (Hit.bBlockingHit)
				return true;
		}

		return false;
	}

	void Explode(AActor Actor, FVector Point)
	{
		// Debug::DrawDebugSphere(Point, 500.0, Duration = 10.0);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Explosion, Point);
		DestroyActor();

		if (Actor != nullptr)
		{
			auto ResponseComp = USplitTraversalTurretProjectileResponseComponent::Get(Actor);
			if (ResponseComp != nullptr)
				ResponseComp.OnHit.Broadcast();
		}
	}
};

event void FOnSplitTraversalTurretProjectileHit();

class USplitTraversalTurretProjectileResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSplitTraversalTurretProjectileHit OnHit;
}