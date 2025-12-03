UCLASS()
class AAcidDissolveSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SphereComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default SphereComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	float GrowthSpeedChangeFactor = 0;
	float CurrentGrowthSpeed = 0;

	float LifeTime = 10;

	float TimeWhenSpawned = MAX_flt;

	float DissolveRadius = 2000;
	// float StartDissolveRadius = 100;

	AActor ActorToMaskCollision;

	/**
	 * Niagara components updated by this sphere dissolve.
	 * We have an array because the actor might have multiple meshes
	 */
	TArray<UNiagaraComponent> NiagaraComps;

	FVector ImpactDirection = FVector::ZeroVector;

	void AddNiagaraComp(UNiagaraSystem Asset, USceneComponent AttachComp, FVector StartPos, float StartRad)
	{
		// UNiagaraComponent NiagaraComp = Niagara::SpawnLoopingNiagaraSystemAttached(Asset, AttachComp);
		UNiagaraComponent NiagaraComp = Niagara::SpawnOneShotNiagaraSystemAttached(Asset, AttachComp);

		if (!devEnsure(NiagaraComp != nullptr, f"AcidDissolveSphere failed to spawn niagara component."))
			return;

		NiagaraComp.SetWorldLocation(StartPos);

		UPrimitiveComponent AttachPrim = Cast<UPrimitiveComponent>(AttachComp);
		if(AttachPrim != nullptr)
		{
			FVector ClosestLocation = StartPos;
			// float Success = AttachPrim.GetClosestPointOnCollision(StartPos, ClosestLocation);
			// if(Success <= 0.0)
			// {
			// 	bool bFoundPoint = FindClosestPointOnComplexMesh(AttachPrim, StartPos, ClosestLocation);
			// 	Print("Found point?", 3.0, bFoundPoint ? FLinearColor::Green : FLinearColor::Red);
			// 	Debug::DrawDebugPoint(ClosestLocation, 20.0, Duration = 1.0);
			// }

			FVector ImpulseDirection = (StartPos - ClosestLocation).GetSafeNormal();

			if(ImpulseDirection.IsZero())
			{
				ImpulseDirection = StartPos - Game::GetMio().GetActorCenterLocation();
				ImpulseDirection.Normalize();
			}

			ImpactDirection = ImpulseDirection;

			// Debug::DrawDebugLine(
			// 	StartPos,
			// 	StartPos + ImpactDirection * 1000.0,
			// 	FLinearColor::Yellow,
			// 	10, 5
			// );

			NiagaraComp.SetVariableVec3(n"DissolveImpulse", ImpulseDirection);
			NiagaraComp.SetVariablePosition(n"DissolveImpulseLocation", StartPos);
			//Debug::DrawDebugLine(StartPos, StartPos + ImpulseDirection * 1000.0, Thickness = 10, Duration = 10.0);
		}


		NiagaraComp.SetVariablePosition(n"DissolvePos", StartPos);
		// NiagaraComp.SetVariablePosition(n"DissolvePos", NiagaraComp.GetWorldTransform().InverseTransformPositionNoScale(StartPos));
		NiagaraComp.SetVariableFloat(n"DissolveRadius", StartRad);


		FVector Origin, Extents;
		ActorToMaskCollision.GetActorBounds(false, Origin, Extents, true);
		const float DissolveMaxRadius = Extents.Size() * 1.0;

		NiagaraComp.SetVariableFloat(n"InitialDissolveTargetRadius", InitalDissolveRadiusTarget);
		NiagaraComp.SetVariableFloat(n"DissolveMaxRadius", DissolveMaxRadius);

		// calculate time until sphere will reach mad radius. 
		float TimeUntilConsumed = AccTime;

		const float A = CurrentGrowthSpeed;
		const float B = GrowthSpeedChangeFactor;
		const float C = DissolveMaxRadius + (Origin - StartPos).Size();
		// const float C = DissolveMaxRadius;
		const float D = InitalDissolveRadiusTarget;

		float PhysTime = 0.0;

		// if(B > 0.0)
		// 	PhysTime = ((Math::Sqrt( (A*A) + (2.0*B*C) - (2.0*B*D) ) - A) / B);
		// else if (A > 0.0)
		// 	PhysTime = (C-D)/A;

		if(GrowthSpeedChangeFactor <= 0.0)
		{
			PhysTime = (DissolveMaxRadius - InitalDissolveRadiusTarget) / CurrentGrowthSpeed;
		}
		else
		{
			PhysTime = Trajectory::GetTimeToReachTarget(
				DissolveMaxRadius-InitalDissolveRadiusTarget,
				CurrentGrowthSpeed,
				GrowthSpeedChangeFactor
			);
		}

		TimeUntilConsumed += PhysTime;

		TimeUntilConsumed *= 1.0;
		
		NiagaraComp.SetVariableFloat(n"DissolveDuration", TimeUntilConsumed);

		//PrintToScreenScaled("DissolveDuration: "+ TimeUntilConsumed, 5.0);

		// ignore scaling
		// NiagaraComp.SetAbsolute(false, false, true);

		NiagaraComps.Add(NiagaraComp);
	}


	void UpdateNiagara(TArray<AAcidDissolveSphere> AllDissolveSpheres)
	{
		// remove any niagara comps that are gone
		for(int i = NiagaraComps.Num() - 1; i >= 0; --i)
		{
			auto IterComp = NiagaraComps[i];

			if(IterComp == nullptr || IterComp.IsBeingDestroyed())
			{
				NiagaraComps.RemoveAt(i);
			}
		}

		// compile data about the other spheres and then update the niagara data
		// on the niagara components mapped with this dissolve sphere
		TArray<FVector> OtherDissolveLocations;
		OtherDissolveLocations.Reserve(AllDissolveSpheres.Num());
		TArray<float32> OtherDissolveRadii;
		OtherDissolveRadii.Reserve(AllDissolveSpheres.Num());
		for (auto OtherDissolveSphere : AllDissolveSpheres)
		{
			if(OtherDissolveSphere == this)
				continue;

			// bool bIntersecting = Math::AreSpheresIntersecting(
			// 	ActorCenterLocation,
			// 	SphereComp.SphereRadius,
			// 	OtherDissolveSphere.ActorCenterLocation,
			// 	OtherDissolveSphere.SphereComp.SphereRadius
			// );

			// if(!bIntersecting)
			// 	continue;

			// we'll only include the sphere that have bigger radius for now.
			if(OtherDissolveSphere.SphereComp.SphereRadius < SphereComp.SphereRadius)
				continue;

			OtherDissolveLocations.Add(OtherDissolveSphere.ActorCenterLocation);
			OtherDissolveRadii.Add(OtherDissolveSphere.SphereComp.SphereRadius);
		}

		SendNiagaraData(OtherDissolveLocations, OtherDissolveRadii);
	}

	void SendNiagaraData(TArray<FVector> OtherDissolveLocations, TArray<float32> OtherDissolveRadii)
	{
		for(auto IterNiagaraComp : NiagaraComps)
		{
			// const FVector DissolvePos = IterNiagaraComp.GetWorldTransform().InverseTransformPosition(ActorCenterLocation);
			// IterNiagaraComp.SetVariablePosition(n"DissolvePos", DissolvePos);
			IterNiagaraComp.SetVariablePosition(n"DissolvePos", ActorCenterLocation);
			const float DissolveRad = SphereComp.SphereRadius;
			IterNiagaraComp.SetVariableFloat(n"DissolveRadius", DissolveRad);

			TArray<FVector> LocalSpaceLocations;
			LocalSpaceLocations.Reserve(OtherDissolveLocations.Num());
			for(int i = 0; i < OtherDissolveLocations.Num(); ++i)
			{
				auto& IterLocation = OtherDissolveLocations[i];
				LocalSpaceLocations.Add(IterNiagaraComp.GetWorldTransform().InverseTransformPositionNoScale(IterLocation));
				// Debug::DrawDebugSphere(IterLocation, OtherDissolveRadii[i], 32, FLinearColor::Blue);
				// Debug::DrawDebugSphere(
				// 	IterNiagaraComp.GetWorldTransform().TransformPositionNoScale(LocalSpaceLocations[i]),
				// 	 OtherDissolveRadii[i]
				// 	 );
				// Debug::DrawDebugSphere(ActorCenterLocation, SphereComp.SphereRadius, 12, FLinearColor::Yellow);
				// Debug::DrawDebugSphere(LocalSpaceLocations[i], OtherDissolveRadii[i], 32, FLinearColor::Blue);
			}

			// NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterNiagaraComp, n"OtherDissolveLocations", LocalSpaceLocations);
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(IterNiagaraComp, n"OtherDissolveLocations", OtherDissolveLocations);
			NiagaraDataInterfaceArray::SetNiagaraArrayFloat(IterNiagaraComp, n"OtherDissolveRadii", OtherDissolveRadii);
		}

	}

	bool FindClosestPointOnComplexMesh(UPrimitiveComponent Prim, FVector QueryPoint, FVector& OutPoint, int TraceAttempts = 32)
	{
		if (Prim == nullptr || TraceAttempts <= 0)
			return false;

		for (int j = 0; j < TraceAttempts; ++j)
		{
			FVector Offset = Math::GetRandomPointInSphere() * Prim.BoundsRadius * 2.0;

			FName BoneName;
			FVector ImpactPoint, ImpactNormal;
			FHitResult HitResult;
			Prim.LineTraceComponent(
				QueryPoint + Offset,
				QueryPoint - Offset,
				true,
				false,
				false,
				ImpactPoint,
				ImpactNormal,
				BoneName,
				HitResult
			);

			// Prim.SphereTraceComponent(
			// 	QueryPoint + Offset,
			// 	QueryPoint - Offset,
			// 	Offset.Size(),
			// 	true,
			// 	true,
			// 	false,
			// 	ImpactPoint,
			// 	ImpactNormal,
			// 	BoneName,
			// 	HitResult
			// );

			if(HitResult.bBlockingHit)
			{
				OutPoint = HitResult.ImpactPoint;
				return true;
			}

			if (HitResult.Time > KINDA_SMALL_NUMBER && HitResult.Time < 1.0 - KINDA_SMALL_NUMBER)
			{
				// OutPoint = WorldTransform.InverseTransformPositionNoScale(HitResult.ImpactPoint);
				OutPoint = HitResult.ImpactPoint;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeWhenSpawned = Time::GameTimeSeconds;
		OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnEndOverlap");
		SphereComp.SphereRadius = DissolveRadius;
		// SphereComp.SphereRadius = StartDissolveRadius;
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
		{
			// auto AcidProjectile = Cast<AAdultDragonAcidProjectile>(OtherActor);
			// if (AcidProjectile == nullptr)
			// 	return;

			// AcidProjectile.HandleOverlapAcidDissolveSphere(this);
			return;
		}

		auto StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		if (StrafeComp == nullptr)
			return;

		StrafeComp.OnBeginOverlapAcidDissolveSphere.Broadcast(this);
	}

	UFUNCTION()
	private void OnEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		if (StrafeComp == nullptr)
			return;

		StrafeComp.OnEndOverlapAcidDissolveSphere.Broadcast(this);
	}

	float InitalDissolveRadiusTarget = 0.0;
	FHazeAcceleratedFloat AccDissolveRadius;
	float TimestampActivated = -1;
	float AccTime = 0.0;

	void SetAcceleratedDissolveRadiusTarget(const float TargetRadius, const float StartRadius, const float Time)
	{
		InitalDissolveRadiusTarget = TargetRadius;
		AccDissolveRadius.SnapTo(StartRadius);
		TimestampActivated = Time::GetGameTimeSeconds();
		AccTime = Time;
	}

	float NiagaraDissolveSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Radius = 0.0;
		if(Time::GetGameTimeSince(TimestampActivated) <= AccTime)
		{
			AccDissolveRadius.AccelerateTo(InitalDissolveRadiusTarget, AccTime, DeltaSeconds);
			DissolveRadius = AccDissolveRadius.Value;
			Radius = DissolveRadius;
			NiagaraDissolveSpeed = AccDissolveRadius.Velocity;
		}
		else
		{
			CurrentGrowthSpeed += GrowthSpeedChangeFactor * DeltaSeconds;
			Radius = DissolveRadius;
			Radius += CurrentGrowthSpeed * DeltaSeconds;
			DissolveRadius = Radius;
			NiagaraDissolveSpeed = CurrentGrowthSpeed;
		}

		SphereComp.SetSphereRadius(Radius, true);

		// const float TImeSince = Time::GetGameTimeSince(TimestampActivated);
		// PrintToScreenScaled("TimeSince: " + TImeSince);

		FVector Origin, Extents;
		ActorToMaskCollision.GetActorBounds(false, Origin, Extents, true);
		if (Radius > Extents.Size()*2.0)
		{
			ActorToMaskCollision.DestroyActor();
			DestroyActor();
		}
		else if (Time::GetGameTimeSince(TimeWhenSpawned) > LifeTime)
			DestroyActor();
	}
};