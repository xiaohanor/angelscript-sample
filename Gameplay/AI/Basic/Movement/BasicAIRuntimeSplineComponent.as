class UBasicAIRuntimeSplineComponent : UActorComponent
{
	private bool bHasSpline = false;
	private FHazeRuntimeSpline CurSpline;
	private float DistAlongSpline;
	private float MoveSpeed;

	float GetSpeed() property
	{
		return MoveSpeed;
	}

	void Reset()
	{
		bHasSpline = false;
		MoveSpeed = 0;
	}

	bool HasSpline()
	{
		return bHasSpline;
	}

	void SetSplineBetweenActors(AActor From, AActor To, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (From == nullptr)
			return;
		if (To == nullptr)
			return;

		TArray<FVector> Locs;
		Locs.Add(From.ActorLocation);
		Locs.Add(To.ActorLocation);
		SetSpline(Locs, From.ActorForwardVector, To.ActorForwardVector, _DistAlongSpline);
	}

	void SetSplineBetweenActors(AActor From, TArray<FVector> IntermediateLocations, AActor To, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (From == nullptr)
			return;
		
		TArray<FVector> Locs;
		Locs.Add(From.ActorLocation);
		Locs.Append(IntermediateLocations);
		Locs.Add(To.ActorLocation);
		SetSpline(Locs, From.ActorForwardVector, To.ActorForwardVector, _DistAlongSpline);
	}

	void SetSplineFromActor(AActor From, TArray<FVector> AdditionalLocations, FVector EndingTangent = FVector::ZeroVector, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (From == nullptr)
			return;

		TArray<FVector> Locs;
		Locs.Add(From.ActorLocation);
		Locs.Append(AdditionalLocations);
		SetSpline(Locs, From.ActorForwardVector, EndingTangent, _DistAlongSpline);
	}

	void SetSplineBetweenActorsWithUpDirection(AActor From, AActor To, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (From == nullptr)
			return;
		if (To == nullptr)
			return;

		TArray<FVector> Locs;
		Locs.Add(From.ActorLocation);
		Locs.Add(To.ActorLocation);
		TArray<FVector> UpDirs;
		UpDirs.Add(From.ActorUpVector);
		UpDirs.Add(To.ActorUpVector);
		SetSpline(Locs, From.ActorForwardVector, To.ActorForwardVector, _DistAlongSpline);
	}

	void SetSplineBetweenActorsWithUpDirection(AActor From, TArray<FVector> IntermediateLocations, TArray<FVector> IntermediateUpdirs, AActor To, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (From == nullptr)
			return;
		
		TArray<FVector> Locs;
		Locs.Add(From.ActorLocation);
		Locs.Append(IntermediateLocations);
		Locs.Add(To.ActorLocation);
		TArray<FVector> UpDirs;
		UpDirs.Add(From.ActorUpVector);
		UpDirs.Append(IntermediateUpdirs);
		UpDirs.Add(To.ActorUpVector);
		SetSpline(Locs, UpDirs, From.ActorForwardVector, To.ActorForwardVector, _DistAlongSpline);
	}

	void SetSplineFromActorWithUpDirection(AActor From, TArray<FVector> AdditionalLocations, TArray<FVector> AdditionalUpdirs, FVector EndingTangent = FVector::ZeroVector, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (From == nullptr)
			return;

		TArray<FVector> Locs;
		Locs.Add(From.ActorLocation);
		Locs.Append(AdditionalLocations);
		TArray<FVector> UpDirs;
		UpDirs.Add(From.ActorUpVector);
		UpDirs.Append(AdditionalUpdirs);
		SetSpline(Locs, UpDirs, From.ActorForwardVector, EndingTangent, _DistAlongSpline);
	}

	void SetSpline(TArray<FVector> Locations, FVector StartingTangent = FVector::ZeroVector, FVector EndingTangent = FVector::ZeroVector, float _DistAlongSpline = 0.0)
	{
		SetSpline(Locations, TArray<FVector>(), StartingTangent, EndingTangent, _DistAlongSpline);
	}

	void SetSpline(TArray<FVector> Locations, TArray<FVector> UpDirections, FVector StartingTangent = FVector::ZeroVector, FVector EndingTangent = FVector::ZeroVector, float _DistAlongSpline = 0.0)
	{
		bHasSpline = false;
		if (Locations.Num() < 2)
			return;

		bHasSpline = true;
		CurSpline.SetPoints(Locations);
		if (UpDirections.Num() == Locations.Num())
			CurSpline.SetUpDirections(UpDirections);
		else 
			CurSpline.SetUpDirections(TArray<FVector>());

		if (StartingTangent.IsZero())
			CurSpline.SetCustomEnterTangentPoint(FVector::ZeroVector);
		else
			CurSpline.SetCustomEnterTangentPoint(Locations[0] - StartingTangent);

		if (EndingTangent.IsZero())
			CurSpline.SetCustomExitTangentPoint(FVector::ZeroVector);
		else
			CurSpline.SetCustomExitTangentPoint(Locations.Last() + EndingTangent);

		DistAlongSpline = _DistAlongSpline;
	}

	void SetSpline(const FHazeRuntimeSpline& _Spline, float _DistAlongSpline = 0.0) property
	{
		bHasSpline = (_Spline.Points.Num() > 1);
		CurSpline = _Spline;
		DistAlongSpline = _DistAlongSpline;
	}

	FHazeRuntimeSpline GetSpline() property
	{
		return CurSpline;
	}

	float GetDistanceAlongSpline() const property
	{
		return DistAlongSpline;
	}

	void SetDistanceAlongSpline(float Dist) property
	{
		DistAlongSpline = Dist;
	}

	bool IsNearEndOfSpline(float WithinDistance) const
	{
		if (!bHasSpline)
			return false;
		return (DistAlongSpline > CurSpline.Length - WithinDistance);
	}

	void MoveAlongSpline(float _Speed)
	{
		MoveSpeed = _Speed;
	}

	float GetSplineAlpha() const
	{
		if (CurSpline.Points.Num() == 0)
			return 0.0;
		if (CurSpline.Length < 0.1)
			return 1.0;
		return DistAlongSpline / CurSpline.Length;
	}
}
