
/**
 * System that handles and sends interaction data to a certain niagara system.
 * 
 * Disclaimer: This might end up being expensive on CPU side. If you the reader, is here because its 
 * to expensive, then let Sydney know and we'll remove this 'feature' from that gameplay bit. 
 * 
 */

 struct FNiagaraInfluence
 {
	// reference to the system we are working with
	UNiagaraComponent Sim;

	// data container for location requests 
	TArray<FNiagaraInfluencePoint> Points;

	// data container for shockwave locations
	TArray<FNiagaraInfluenceShockwavePoint> ShockwavePoints;

	// actors whose staticmesh/skeletalmesh will influence the system.
	TArray<AActor> SourceActors;

	bool bActive = false;

	void Init(UNiagaraComponent InSystem) 
	{
		Sim = InSystem;

		bActive = true;
	}

	void Reset()
	{
		Points.Reset();
		ShockwavePoints.Reset();
		SourceActors.Reset();

		Sim = nullptr;

		bActive = false;
	}

	void Tick(const float Dt)
	{
		if(bActive == false)
			return;

		if(Sim == nullptr)
		{
			devError("Send a screenshot to sydney pls, Sim == nullptr");
			return;
		}

		ProcessActors();
		ProcessPoints(Dt);
	}

	void ProcessActors()
	{
		if(SourceActors.Num() <= 0)
			return;

		// PrintToScreenScaled("NumSourceActors: " + SourceActors.Num());
		// for(auto IterSourceActor : SourceActors)
		// {
		// 	Debug::DrawDebugSphere(
		// 		IterSourceActor.GetActorLocation(),
		// 		IterSourceActor.GetActorLocalBoundingBox(false).Extent.Size() * 0.5,
		// 		12, 
		// 		FLinearColor::Red,
		// 		5,
		// 		0.0,
		// 		false
		// 	);
		// }

		NiagaraDIRigidMeshCollision::SetSourceActors(Sim, n"bobi", SourceActors);
	}

	// process the queued up points for influencing the niagara fluid sim
	void ProcessPoints(const float Dt)
	{
		const int NumPoints = Points.Num() + ShockwavePoints.Num();
		if(NumPoints <= 0)
			return;

		TArray<FNiagaraInfluencePoint> AllPoints;
		AllPoints.Reserve(NumPoints);
		AllPoints.Append(Points);

		// process shockwave points
		for(FNiagaraInfluenceShockwavePoint& IterShockwave : ShockwavePoints)
		{
			IterShockwave.UpdateShockwaveLocation();
			AllPoints.Add(IterShockwave.Point);
		}

		TArray<FVector> RelativeLocations;
		TArray<float32> DivergenceScales;
		TArray<float32> VelocityScales;
		TArray<float32> SizeScales;
		TArray<float32> Timestamps;
		TArray<float32> LifeTimes;

		RelativeLocations.Reserve(NumPoints);
		DivergenceScales.Reserve(NumPoints);
		VelocityScales.Reserve(NumPoints);
		SizeScales.Reserve(NumPoints);
		Timestamps.Reserve(NumPoints);
		LifeTimes.Reserve(NumPoints);

		bool bClearPoints = true;

		/**
		 * We will handle the life time of the particles here for now, because we
		 * need to iterate over the particles and update the relative location anyway.
		 * Niagara will simply look at the array and allocate particles based on that.
		 * 
		 * A better way of doing this is for niagara to handle it. We need to figure out how
		 * to send a array of components to niagara for this to work...
		 */

		for(FNiagaraInfluencePoint& P : AllPoints)
		{
			// temp handling of the lifetime. Need to rethink this. all the points need to be finished before we clear
			const float TimeActive = Time::GetGameTimeSince(P.InfluenceParams.Timestamp);
			if(TimeActive <= P.InfluenceParams.LifeTime)
				bClearPoints = false;

			// if(TimeActive > P.InfluenceParams.LifeTime)
			// {
			// 	continue;
			// }

			// we'll transform the location into the niagara systems space in order to fix the locations lagging behind
			const FVector WorldPos = P.GetWorldLocation();
			const FVector RelativePosToSim = Sim.GetWorldTransform().InverseTransformPosition(WorldPos);

			// const FVector DebugWorldLocation = Sim.GetWorldTransform().TransformPosition(RelativePosToSim);
			// 	Debug::DrawDebugPoint(
			// 	DebugWorldLocation,
			// 	10,
			// 	TimeActive <= P.InfluenceParams.LifeTime ? FLinearColor::Green : FLinearColor::Red,
			// 	0.0,
			// 	true
			// );

			RelativeLocations.Add(RelativePosToSim);

			// we don't want to shrink the array size atm, but we'll flag that these particles are dead.
			if(TimeActive > P.InfluenceParams.LifeTime)
			{
				DivergenceScales.Add(0.0);
				VelocityScales.Add(0.0);
				SizeScales.Add(0.0);
			}
			else
			{
				DivergenceScales.Add(P.InfluenceParams.DivergenceScale);
				VelocityScales.Add(P.InfluenceParams.VelocityScale);
				SizeScales.Add(P.InfluenceParams.SizeScale);
			}

			Timestamps.Add(P.InfluenceParams.Timestamp);

			// we are strictly pruning points based on if the array index is valid in Niagara atm. 
			LifeTimes.Add(P.InfluenceParams.LifeTime);
		}

		// safety net.
		if(NumPoints > 1000)
		{
			bClearPoints = true;
		}

		// PrintToScreenScaled("Num Points Added: " + NumPoints);
		// PrintToScreenScaled("Num Points Sent: " + RelativeLocations.Num());

		if(bClearPoints)
		{
			ShockwavePoints.Reset();
			Points.Reset();
			RelativeLocations.Reset();
			DivergenceScales.Reset();
			VelocityScales.Reset();
			SizeScales.Reset();
			Timestamps.Reset();
			LifeTimes.Reset();
		}
		
		// 	PrintToScreenScaled("LifeTime: " + LifeTimes.Last());

		NiagaraDataInterfaceArray::SetNiagaraArrayVector(Sim, n"Locations", RelativeLocations);
		NiagaraDataInterfaceArray::SetNiagaraArrayFloat(Sim, n"DivergenceScales", DivergenceScales);
		NiagaraDataInterfaceArray::SetNiagaraArrayFloat(Sim, n"VelocityScales", VelocityScales);
		NiagaraDataInterfaceArray::SetNiagaraArrayFloat(Sim, n"SizeScales", SizeScales);
		NiagaraDataInterfaceArray::SetNiagaraArrayFloat(Sim, n"LifeTimes", LifeTimes);
		NiagaraDataInterfaceArray::SetNiagaraArrayFloat(Sim, n"Timestamps", Timestamps);
	}

	void TestWithPlayer(AHazePlayerCharacter Player)
	{
		// TArray<AActor> SourceActors;
		// SourceActors.Reserve(2);
		// SourceActors.Add(Game::GetMio());
		// SourceActors.Add(Game::GetZoe());
		// UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		// NiagaraDIRigidMeshCollision::SetSourceActors(PostProcessComp.CameraParticlesComponent, n"MeshCollisionQuery", SourceActors);

		for(int i = 0; i < 1; ++i)
		{
			FNiagaraInfluencePoint Point;
			Point.Instigator = Player;
			Point.RelativeComp = Player.AttachmentRoot;
			Point.RelativeLocation = FVector(0.0, 0.0, float(i) * 45);
			Point.InfluenceParams.LifeTime = 0.0;
			Point.InfluenceParams.DivergenceScale = 0.0;
			Point.InfluenceParams.VelocityScale = 1.0;
			Point.InfluenceParams.SizeScale = 1.0;
			Point.InfluenceParams.Timestamp = float32(Time::GetGameTimeSeconds());
			Points.Add(Point);
		}

	}

	void AddPointsShockwave(FNiagaraInfluenceShockwaveData Shockwave)
	{
		const float MaxRadius = Shockwave.LifeTime * Shockwave.ScaleSpeed * Shockwave.StartRadius;
		int NumParticles = int(MaxRadius / 1000.0);
		NumParticles = 20;

		FVector AvgPlayerPos = (Game::GetMio().GetActorLocation() + Game::GetZoe().GetActorLocation()) * 0.5;
		AvgPlayerPos.Z = Shockwave.SpawnLocation.Z;
		FVector TargetDirection = AvgPlayerPos - Shockwave.SpawnLocation;
		TargetDirection.Normalize();

		for(int i = 0; i < NumParticles; ++i)
		{
			FNiagaraInfluenceShockwavePoint ShockwavePoint;
			auto& Point = ShockwavePoint.Point;
			Point.Instigator = nullptr;
			Point.RelativeComp = Sim;
			Point.RelativeBoneName = NAME_None;
			Point.RelativeLocation = Sim.GetWorldTransform().InverseTransformPosition(Shockwave.SpawnLocation);
			Point.InfluenceParams.LifeTime = float32(Shockwave.LifeTime);
			Point.InfluenceParams.DivergenceScale = 100.0;
			Point.InfluenceParams.VelocityScale = 2.0;
			Point.InfluenceParams.SizeScale = 10.0;
			Point.InfluenceParams.Timestamp = float32(Time::GetGameTimeSeconds());
			ShockwavePoint.Shockwave = Shockwave;

			float RadAlpha = float(i) / float(NumParticles);
			float Rad = Math::Lerp(-PI*0.5, PI*0.5, RadAlpha);
			float Angle = Math::RadiansToDegrees(Rad);
			ShockwavePoint.ShockwaveDirection = TargetDirection.RotateAngleAxis(Angle, FVector::UpVector);
			ShockwavePoint.ShockwaveDirection.Normalize();

			// Debug::DrawDebugArrow(
			// 	Shockwave.SpawnLocation,
			// 	Shockwave.SpawnLocation + ShockwavePoint.ShockwaveDirection * 1000.0,
			// 	100.0,
			// 	FLinearColor::Yellow,
			// 	10.0,
			// 	2.0, 
			// 	false
			// );

			ShockwavePoints.Add(ShockwavePoint);
		}
	}

	void AddPointsForPrimitiveCollision(UPrimitiveComponent Prim, FName OptionalBoneName = NAME_None)
	{
		int NumPoints = 10;

		TArray<FVector> Locations;
		Locations.Reserve(NumPoints);

		const float Radius = Prim.GetComponentLocalBoundingBox().Extent.Size() * 0.5;

		for(int i = 0; i < NumPoints; ++i)
		{
			FVector OutP;
			Prim.GetClosestPointOnCollision(
				Prim.GetBoundsOrigin() + (Math::GetRandomPointOnSphere() * Radius), 
				OutP, 
				OptionalBoneName
			);

			// Debug::DrawDebugPoint(OutP, 10, FLinearColor::Blue, 2.0, false);
			// PrintToScreenScaled("Pos: " + OutP, 3.0);

			Locations.Add(OutP);
		}

		for(int i = 0; i < NumPoints; ++i)
		{
			FNiagaraInfluencePoint Point;
			Point.Instigator = Prim;
			Point.RelativeComp = Prim;
			Point.RelativeBoneName = OptionalBoneName;
			Point.RelativeLocation = Locations[i];
			// Point.SetRelativeLocationFromWorldLocation(Locations[i]);
			Point.InfluenceParams.LifeTime = 4.0;
			Point.InfluenceParams.DivergenceScale = 100.0;
			Point.InfluenceParams.VelocityScale = 5.0;
			Point.InfluenceParams.SizeScale = 10.0;
			Point.InfluenceParams.Timestamp = float32(Time::GetGameTimeSeconds());

			Points.Add(Point);
		}

	}

	void AddPointsForMeshBones(UHazeSkeletalMeshComponentBase Mesh)
	{

		int NumBones = Mesh.GetNumBones();
		for(int i = 0; i < NumBones; ++i)
		{
			FNiagaraInfluencePoint Point;
			Point.Instigator = Mesh;
			Point.RelativeComp = Mesh;
			Point.RelativeBoneName = Mesh.GetBoneName(i);
			Point.RelativeLocation = FVector::ZeroVector;

			Point.InfluenceParams.LifeTime = 40.0;
			Point.InfluenceParams.DivergenceScale = 50.0;
			Point.InfluenceParams.VelocityScale = 50.0;
			Point.InfluenceParams.SizeScale = 50.0;

			Point.InfluenceParams.Timestamp = float32(Time::GetGameTimeSeconds());

			// compare to other points check if this one can get skipped
			// because its to close to the to the other ones
			bool bAddPoint = true;
			auto ThisPointLocation = Point.GetWorldLocation();
			for(auto IterP : Points)
			{
				auto PLoc = IterP.GetWorldLocation();
				const float DistSQBetween = (PLoc-ThisPointLocation).SizeSquared();
				if(DistSQBetween < 2500.0)
				{
					bAddPoint = false;
					break;
				}
			}

			if(bAddPoint)
			{
				Points.Add(Point);
			}

		}

	}	

	void AddPillarPointsForComp(USceneComponent Comp)
	{
		for(int i = 0; i < 6; ++i)
		{
			FNiagaraInfluencePoint Point;
			Point.RelativeComp = Comp;
			Point.RelativeLocation = FVector(0.0, 0.0, float(i) * 150);
			// Point.SetRelativeLocationFromWorldLocation(FVector(0.0, 0.0, float(i) * 150));
			Point.InfluenceParams.DivergenceScale = 100.0;
			Point.InfluenceParams.VelocityScale = 50.0;
			Point.InfluenceParams.SizeScale = 5.0;
			Point.InfluenceParams.LifeTime = 4.0;
			Point.InfluenceParams.Timestamp = float32(Time::GetGameTimeSeconds());
			Points.Add(Point);
		}
	}

	void RemovePointsForComp(USceneComponent Comp)
	{
		for(auto& IterPoint : Points)
		{
			if(IterPoint.RelativeComp == Comp)
			{
				IterPoint.InfluenceParams.LifeTime = 0.0;
			}
		}
	}

	void AddPoint(FNiagaraInfluencePoint Point)
	{
		Points.Add(Point);
	}

	void ResetAllPoints()
	{
		Points.Reset();
		ShockwavePoints.Reset();
	}

	void AddSourceActor(AActor Actor)
	{
		Actor.Tags.AddUnique(n"FluidSim");
		SourceActors.AddUnique(Actor);
	}

	void RemoveSourceActor(AActor Actor)
	{
		Actor.Tags.Remove(n"FluidSim");
		SourceActors.Remove(Actor);
	}
 }

// Inner params that are associated with the location and sent to niagara later
struct FNiagaraInfluenceParams
{
	UPROPERTY()
	float32 VelocityScale = 1.0;
	UPROPERTY()
	float32 DivergenceScale = 1.0;
	UPROPERTY()
	float32 SizeScale = 1.0;
	UPROPERTY()
	float32 LifeTime = 1.0;
	UPROPERTY()
	float32 Timestamp = -1.0;
}

// data that we will iterate over in here.
struct FNiagaraInfluencePoint
{
	UPROPERTY()
	FName RelativeBoneName = NAME_None;
	UPROPERTY()
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY()
	USceneComponent RelativeComp = nullptr;
	UPROPERTY()
	FNiagaraInfluenceParams InfluenceParams;
	UPROPERTY()
	FInstigator Instigator = nullptr;

	FVector GetWorldLocation() const
	{
		if(RelativeComp == nullptr)
		{
			devError("Send screenshot to Sydney please, RelativeComp == nullptr");
			return FVector::ZeroVector;
		}
		return RelativeComp.GetSocketTransform(RelativeBoneName).TransformPositionNoScale(RelativeLocation);
	}

	void SetRelativeLocationFromWorldLocation(FVector WorldLocation)
	{
		RelativeLocation = RelativeComp.GetSocketTransform(RelativeBoneName).InverseTransformPositionNoScale(WorldLocation);
	}
}

struct FNiagaraInfluenceShockwavePoint
{
	// this data will be updated per frame
	UPROPERTY()
	FNiagaraInfluencePoint Point;

	// settings for the shockwave.
	UPROPERTY()
	FNiagaraInfluenceShockwaveData Shockwave;

	UPROPERTY()
	FVector ShockwaveDirection = FVector::ZeroVector;

	void UpdateShockwaveLocation()
	{
		float ShockwaveTime = Time::GetGameTimeSince(Point.InfluenceParams.Timestamp);
		ShockwaveTime = Math::Clamp(ShockwaveTime, 0.0, Shockwave.LifeTime);

		FVector Origin = Shockwave.SpawnLocation;
		FVector Delta = ShockwaveDirection * Shockwave.StartRadius * ShockwaveTime * Shockwave.ScaleSpeed;

		Point.SetRelativeLocationFromWorldLocation(Origin+Delta);
	}
}

struct FNiagaraInfluenceShockwaveData
{
	UPROPERTY()
	FVector SpawnLocation = FVector::ZeroVector;

	UPROPERTY()
	float LifeTime = -1;

	UPROPERTY()
	float ScaleSpeed = 0;

	UPROPERTY()
	float StartRadius = 0;

	UPROPERTY()
	float Thickness = 0;
}