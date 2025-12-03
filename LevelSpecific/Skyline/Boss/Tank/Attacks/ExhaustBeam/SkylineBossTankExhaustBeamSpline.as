class ASkylineBossTankExhaustBeamSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraComp;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.5;

	FHazeRuntimeSpline RuntimeSpline;

	TArray<FVector> Points;
	TArray<FVector> Velocities;
	TArray<FVector> TargetVelocities;

	float Speed = 4000.0; // 5000.0 // 15000.0
	float Thickness = 1000.0;

	TPerPlayer<bool> bInsideRadiusLastFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = 0; i < Points.Num(); i++)
		{
			Points[i] += Velocities[i] * DeltaSeconds;
			Velocities[i] = Math::Lerp(Velocities[i], TargetVelocities[i], DeltaSeconds * 1.0);
		}

		UpdateSpline();

		for (auto Player : Game::Players)
		{
			float SplineDistance = RuntimeSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation);

			FVector ClosestLocation;
			FQuat ClosestQuat;

			RuntimeSpline.GetLocationAndQuatAtDistance(SplineDistance, ClosestLocation, ClosestQuat);

			float ClosestRightVectorProjection = FTransform(ClosestQuat, ClosestLocation, FVector::OneVector).InverseTransformPositionNoScale(Player.ActorLocation).Y;

//			Debug::DrawDebugPoint(ClosestLocation, 30.0, FLinearColor::Red);

//			PrintToScreen("!!! " + Player.Name + " RightVector: " + ClosestRightVectorProjection, 0.0, FLinearColor::DPink);

			float Distance = Player.ActorLocation.Distance(ClosestLocation);

			if (IsContinuouslyGrounded(Player) && Distance < Thickness)
			{
				if ((!bInsideRadiusLastFrame[Player] && ClosestRightVectorProjection > 0.0) || (bInsideRadiusLastFrame[Player] && ClosestRightVectorProjection < 0.0))
				{
					Player.DamagePlayerHealth(Damage);
//					Debug::DrawDebugSphere(Player.ActorLocation, 200.0, 12, FLinearColor::Red, 10.0, 1.0);
				}
			}

			bInsideRadiusLastFrame[Player] = ClosestRightVectorProjection > 0.0;
		}
	}

	void AddBeamSplinePoint(FVector Location, FVector Velocity)
	{
		Points.Add(Location);
		Velocities.Add(Velocity * 8.0);
		TargetVelocities.Add(Velocity);
	}	

	void UpdateSpline()
	{
		RuntimeSpline.SetPoints(Points);

		int Resolution = 2000;
		int Samples = int(RuntimeSpline.Length / Resolution);

		TArray<FVector> NiagaraLocations;
		RuntimeSpline.GetLocations(NiagaraLocations, Samples);
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(NiagaraComp, n"RuntimeSplinePoints", NiagaraLocations);

//		for (int i = 0; i < NiagaraLocations.Num(); i++)
//			Debug::DrawDebugPoint(NiagaraLocations[i], 20.0, FLinearColor::Red);


//		DrawDebugSpline();
	}

	void DrawDebugSpline()
	{
		FLinearColor Color = FLinearColor::Yellow;

		float Size = 300.0;

		int Resolution = 1000;
		int Samples = int(RuntimeSpline.Length / Resolution);

		TArray<FVector> Locations;
		RuntimeSpline.GetLocations(Locations, Samples);

		TArray<FQuat> Quats;
		RuntimeSpline.GetQuats(Quats, Samples);

		for (int i = 0; i < Samples - 1; i++)
		{
			Debug::DrawDebugLine(Locations[i], Locations[i + 1], Color, Size);
			Debug::DrawDebugLine(Locations[i], Locations[i] + Quats[i].RightVector * 500.0, FLinearColor::Green, Size);
		}

		for (int i = 0; i < Points.Num(); i++)
			Debug::DrawDebugPoint(Points[i], Size * 0.04, FLinearColor::Red);
	}

	bool IsContinuouslyGrounded(AHazePlayerCharacter Player)
	{
		auto MoveComp = GravityBikeFree::GetGravityBike(Player).MoveComp;
		return MoveComp.PreviousHadGroundContact() && MoveComp.HasGroundContact();
	}
}