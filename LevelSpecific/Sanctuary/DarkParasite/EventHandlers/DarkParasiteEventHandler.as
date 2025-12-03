UCLASS(Abstract)
class UDarkParasiteEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDarkParasiteUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UDarkParasiteUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Focused(FDarkParasiteTargetData TargetData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Unfocused(FDarkParasiteTargetData TargetData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Attached(FDarkParasiteTargetData TargetData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Detached(FDarkParasiteTargetData TargetData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Grabbed(FDarkParasiteGrabData GrabData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Released(FDarkParasiteGrabData GrabData) { }

	// TODO: Blackbox full of magic numbers
	// TODO: Store current location somewhere and interpolate from there
	//  right now we're popping back to start location every grab
	UFUNCTION(BlueprintCallable)
	void CalculateTentacleLocation(FVector&out StartLocation,
		FVector&out StartTangentLocation,
		FVector&out EndLocation,
		FVector&out EndTangentLocation,
		int Index,
		float TangentOffset = 250.0) const
	{
		StartLocation = GetStartLocation(Index);
		StartTangentLocation = GetStartTangent(Index, TangentOffset);
		EndLocation = GetEndLocation(Index);
		EndTangentLocation = GetEndTangent(Index);

		// Pseudo-random value per-index to juice things up a bit
		// Is it any good? Who knows.
		const float RandomValue = 0.5 + Math::Sin(UserComp.GrabbedData.Timestamp * Index * 24.0) / 2.0;

		if (UserComp.GrabbedData.IsValid())
		{
			const float GrabDelay = DarkParasite::GrabDelay - (DarkParasite::GrabRoll * RandomValue);
			const float Alpha = (GrabDelay != 0.0) ? 
				Time::GetGameTimeSince(UserComp.GrabbedData.Timestamp) / GrabDelay : 
				1.0;

			float LocationAlpha = Math::SinusoidalOut(0.0, 1.0, Math::Clamp(Alpha, 0.0, 1.0));
			EndLocation = Math::CubicInterp(StartLocation,
				StartTangentLocation,
				EndLocation,
				EndTangentLocation,
				LocationAlpha);

			float ConstrictAlpha = Math::EaseOut(0.0, 1.0, 1.0 - Math::Clamp(Alpha - 0.7, 0.0, 1.0), 8.0);
			StartTangentLocation = StartTangentLocation * ConstrictAlpha;
			EndTangentLocation = EndTangentLocation * ConstrictAlpha;
		}

		StartTangentLocation += StartLocation;
		EndTangentLocation += EndLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetStartLocation(int Index) const
	{
		return UserComp.AttachedData.WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetStartTangent(int Index, float TangentOffset = 250.0) const
	{
		FVector Tangent = FVector::ZeroVector;
		if (UserComp.GrabbedData.IsValid())
		{
			const float AngularOffset = (360.0 / DarkParasite::NumTentacles) * Index;
			const FVector Direction = (UserComp.AttachedData.WorldLocation - UserComp.GrabbedData.WorldLocation).GetSafeNormal();
			
			FVector UpVector = FVector::UpVector; 
			if (Math::Abs(UpVector.DotProduct(Direction)) > 0.99)
				UpVector = FVector::RightVector;

			FRotator AxisAngle = Math::RotatorFromAxisAndAngle(Direction, AngularOffset);
			const FRotator Rotation = FRotator::MakeFromZX(UpVector, Direction).Compose(AxisAngle);

			Tangent = Rotation.RightVector * TangentOffset;
		}

		return Tangent;
	}

	UFUNCTION(BlueprintPure)
	FVector GetEndLocation(int Index) const
	{
		if (UserComp.GrabbedData.IsValid())
			return UserComp.GrabbedData.WorldLocation;

		return UserComp.AttachedData.WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetEndTangent(int Index) const
	{
		return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintPure)
	int GetNumTentacles() const
	{
		return DarkParasite::NumTentacles;
	}
}