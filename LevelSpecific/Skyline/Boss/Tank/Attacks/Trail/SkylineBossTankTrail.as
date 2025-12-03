class ASkylineBossTankTrail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraComp;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.5;

	UPROPERTY(EditDefaultsOnly)
	float MaxLength = 40000.0;

	FHazeRuntimeSpline RuntimeSpline;

	TArray<FVector> Points;

	float Thickness = 500.0;

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
		UpdateSpline();

		for (auto Player : Game::Players)
		{
			float SplineDistance = RuntimeSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation);

			FVector ClosestLocation;
			FQuat ClosestQuat;

			RuntimeSpline.GetLocationAndQuatAtDistance(SplineDistance, ClosestLocation, ClosestQuat);

			float ClosestRightVectorProjection = FTransform(ClosestQuat, ClosestLocation, FVector::OneVector).InverseTransformPositionNoScale(Player.ActorLocation).Y;

			Debug::DrawDebugPoint(ClosestLocation, 30.0, FLinearColor::Red);

			float Distance = Player.ActorLocation.Distance(ClosestLocation);

			if (IsContinuouslyGrounded(Player) && Distance < Thickness)
			{
				if ((!bInsideRadiusLastFrame[Player] && ClosestRightVectorProjection > 0.0) || (bInsideRadiusLastFrame[Player] && ClosestRightVectorProjection < 0.0))
				{
					Player.DamagePlayerHealth(Damage);
					Debug::DrawDebugSphere(Player.ActorLocation, 200.0, 12, FLinearColor::Red, 10.0, 1.0);
				}
			}

			bInsideRadiusLastFrame[Player] = ClosestRightVectorProjection > 0.0;
		}
	}

	void AddTrailSplinePoint(FVector Location)
	{
		Points.Add(Location);
	}	

	void UpdateSpline()
	{
		if (RuntimeSpline.Length > MaxLength)
			Points.RemoveAt(0);

		RuntimeSpline.SetPoints(Points);

		int Resolution = 1000;
		int Samples = int(RuntimeSpline.Length / Resolution);

		TArray<FVector> NiagaraLocations;
		RuntimeSpline.GetLocations(NiagaraLocations, Samples);
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(NiagaraComp, n"RuntimeSplinePoints", NiagaraLocations);

//		for (int i = 0; i < NiagaraLocations.Num(); i++)
//			Debug::DrawDebugPoint(NiagaraLocations[i], 20.0, FLinearColor::Red);

		DrawDebugSpline();
	}

	void DrawDebugSpline()
	{
		FLinearColor Color = FLinearColor::Yellow;

		float Size = 150.0;

		int Resolution = 300;
		int Samples = int(RuntimeSpline.Length / Resolution);

		TArray<FVector> Locations;
		RuntimeSpline.GetLocations(Locations, Samples);

		TArray<FQuat> Quats;
		RuntimeSpline.GetQuats(Quats, Samples);

		for (int i = 0; i < Samples - 1; i++)
		{
			Debug::DrawDebugLine(Locations[i], Locations[i + 1], Color, Size);
//			Debug::DrawDebugLine(Locations[i], Locations[i] + Quats[i].RightVector * 500.0, FLinearColor::Green, Size);
		}

//		for (int i = 0; i < Points.Num(); i++)
//			Debug::DrawDebugPoint(Points[i], Size * 0.04, FLinearColor::Red);
	}

	bool IsContinuouslyGrounded(AHazePlayerCharacter Player)
	{
		auto MoveComp = GravityBikeFree::GetGravityBike(Player).MoveComp;
		return MoveComp.PreviousHadGroundContact() && MoveComp.HasGroundContact();
	}
}