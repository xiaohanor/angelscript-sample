class AMedallionPlayerMergingCompanionFocus : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillBoard;

	bool bBelongsToMio = false;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	FHazeRuntimeSpline OscillatingPathSpline;
	TArray<FVector> PathPoints;
	float CurrentSplineDistance;

	ASanctuaryBossMedallionHydraReferences Refs;
	UMedallionPlayerComponent SomeMedallionComp;
	UMedallionPlayerMergeHighfiveJumpComponent HighFiveComp;
	FHazeAcceleratedVector AccHighfiveLocation;

	bool Cache()
	{
		if (Mio == nullptr || Refs == nullptr)
		{
			Mio = Game::Mio;
			Zoe = Game::Zoe;
			SomeMedallionComp = UMedallionPlayerComponent::GetOrCreate(Mio);
			HighFiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Mio);
			TListedActors<ASanctuaryBossMedallionHydraReferences> ExistingRefs;
			Refs = ExistingRefs.Single;
		}
		return Refs != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!Cache())
			return;

		if (SomeMedallionComp.IsMedallionCoopFlying())
			return;

		const float HeightOffset = MedallionConstants::Highfive::OscillatingCompanionsUpwardsOffset + 
									MedallionConstants::Highfive::OscillatingCompanionsAddedUpwardsOffset * 
									SomeMedallionComp.HighfiveZoomAlpha;
		const FVector MioLocation = Mio.ActorLocation + FVector::UpVector * HeightOffset;
		const FVector ZoeLocation = Zoe.ActorLocation + FVector::UpVector * HeightOffset;
		const FVector BetweenPlayers = MioLocation - ZoeLocation;
		const FVector LocationInBetween = ZoeLocation + BetweenPlayers * 0.5;

		if (HighFiveComp.IsHighfiveJumping() || HighFiveComp.IsInHighfiveFail())
		{
			// out of view location
			const float SignDirection = bBelongsToMio ? -1.0 : 1.0;
			const FVector OutOfViewDirection = Mio.ViewRotation.RightVector * 5000 * SignDirection;
			const FVector OutOfViewLocation = LocationInBetween + OutOfViewDirection;

			AccHighfiveLocation.AccelerateTo(OutOfViewLocation, 3.0, DeltaSeconds);
			const FVector Delta = AccHighfiveLocation.Value - ActorLocation;
			FVector Heading = ActorForwardVector;
			if (Delta.Size() > KINDA_SMALL_NUMBER)
				Heading = Delta.GetSafeNormal();
			SetActorLocation(AccHighfiveLocation.Value);
			SetActorRotation(FRotator::MakeFromXZ(Heading, FVector::UpVector));
			return;
		}

		const float OutwardsOffset = MedallionConstants::Highfive::OscillatingCompanionsBehindPlayersOffset;

		float MergingDist = Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(LocationInBetween);
		FTransform InBetweenSplineTransform = Refs.SideScrollerSplineLocker.Spline.GetWorldTransformAtSplineDistance(MergingDist);

		float TiltDegrees = MedallionConstants::Highfive::OscillatingCompanionsCircleTiltDegrees;
		float Right = Math::Sin(Math::DegreesToRadians(TiltDegrees));
		float Up = Math::Cos(Math::DegreesToRadians(TiltDegrees));
		FVector OutwardsTilt = (InBetweenSplineTransform.Rotation.UpVector * Up + InBetweenSplineTransform.Rotation.RightVector * Right).GetSafeNormal();
		FRotator Tilted = FRotator::MakeFromXZ(BetweenPlayers.GetSafeNormal(), OutwardsTilt);

		int Granularity = 10;
		PathPoints.Reset(Granularity);
		for (int iPoint = 0; iPoint < Granularity; ++iPoint)
		{
			FVector OffsetDirection = FQuat(Tilted.UpVector, Math::DegreesToRadians(360.0 / Granularity * iPoint)).RightVector;
			FVector Offset = OffsetDirection * Math::Max((BetweenPlayers.Size() * 0.5) + OutwardsOffset, 200);
			FVector PointLocation = LocationInBetween + Offset;
			if (SanctuaryMedallionHydraDevToggles::Draw::CompanionMerging.IsEnabled())
				Debug::DrawDebugSphere(PointLocation, 30, bDrawInForeground = true);

			PathPoints.Add(PointLocation);
		}

		const float Speed = MedallionConstants::Highfive::OscillatingCompanionsSpeed;
		CurrentSplineDistance += DeltaSeconds * Speed;
		CurrentSplineDistance = Math::Wrap(CurrentSplineDistance, 0.0, OscillatingPathSpline.Length);

		OscillatingPathSpline.SetPoints(PathPoints);
		OscillatingPathSpline.SetLooping(true);
		FVector TowardsEnd = PathPoints.Last() - PathPoints[0];
		OscillatingPathSpline.SetCustomEnterTangentPoint(TowardsEnd.GetSafeNormal());

		FVector Locationy;
		FQuat Rotationy;
		float ExtraDistance = bBelongsToMio ? 0.0 : OscillatingPathSpline.Length * 0.5;
		float FinalDistance = Math::Wrap(CurrentSplineDistance + ExtraDistance, 0.0, OscillatingPathSpline.Length);
		OscillatingPathSpline.GetLocationAndQuatAtDistance(FinalDistance, Locationy, Rotationy);

		SetActorLocation(Locationy);
		SetActorRotation(Rotationy);
		AccHighfiveLocation.SnapTo(ActorLocation);

		if (SanctuaryMedallionHydraDevToggles::Draw::CompanionMerging.IsEnabled())
		{
			Debug::DrawDebugString(LocationInBetween, "companion oscillating\nlocation");
			OscillatingPathSpline.DrawDebugSpline();
			Debug::DrawDebugSphere(LocationInBetween, bDrawInForeground = true);
			Debug::DrawDebugLine(LocationInBetween, LocationInBetween + Tilted.UpVector * 1000.0, ColorDebug::Gray, 10, 0.0, true);
		}
	}
};