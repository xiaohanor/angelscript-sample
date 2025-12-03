class AMedallionPlayerMergingHighfiveTargetLocation : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent BillBoard;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;
	ASanctuaryBossMedallionHydraReferences Refs;
	UMedallionPlayerComponent SomeMedallionComp;
	UMedallionPlayerMergeHighfiveJumpComponent SomeHighfiveComp;

	bool Cache()
	{
		if (Mio == nullptr || Refs == nullptr)
		{
			Mio = Game::Mio;
			Zoe = Game::Zoe;
			SomeMedallionComp = UMedallionPlayerComponent::GetOrCreate(Mio);
			SomeHighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Mio);
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

		FVector MioLocation = Mio.ActorLocation;
		FVector ZoeLocation = Zoe.ActorLocation;
		FVector BetweenPlayers = MioLocation - ZoeLocation;
		FVector LocationInBetween = ZoeLocation + BetweenPlayers * 0.5;
		FTransform InBetweenTransform = Refs.SideScrollerSplineLocker.Spline.GetClosestSplineWorldTransformToWorldLocation(LocationInBetween);

		if (SanctuaryMedallionHydraDevToggles::Draw::Highfive.IsEnabled())
		{
			const FVector SidewaysOffset = ActorForwardVector * MedallionConstants::Highfive::HighfivePlayerSidewaysOffset;
			Debug::DrawDebugString(ActorCenterLocation, "highfive\nlocation");
			Debug::DrawDebugSphere(ActorCenterLocation + SidewaysOffset * -1.0, 20, LineColor = Game::Mio.GetPlayerUIColor(), bDrawInForeground = true);
			Debug::DrawDebugSphere(ActorCenterLocation + SidewaysOffset, 20, LineColor = Game::Zoe.GetPlayerUIColor(), bDrawInForeground = true);
			Debug::DrawDebugSphere(ActorCenterLocation, 40, LineColor = ColorDebug::Carrot, bDrawInForeground = true);
			Debug::DrawDebugCircle(LocationInBetween, SomeHighfiveComp.GetHighfiveJumpTriggerDistance() * 0.5, 30, ColorDebug::Carrot, 3, FVector::UpVector, InBetweenTransform.Rotation.ForwardVector, bDrawInForeground = true);
		}

		if (SomeHighfiveComp.IsHighfiveJumping())
			return;

		FVector FinalLocation = InBetweenTransform.Location;
		if (MedallionConstants::Highfive::bHighfiveHeightBasedOnPlayers)
		{
			float MinHeight = Math::Min(MioLocation.Z, ZoeLocation.Z);
			float MaxHeight = Math::Max(MioLocation.Z, ZoeLocation.Z);
			FinalLocation.Z = Math::Lerp(MinHeight, MaxHeight, 1);
		}
		FinalLocation += InBetweenTransform.Rotation.RightVector * MedallionConstants::Highfive::HighfiveOffsetOutwards;
		FinalLocation += InBetweenTransform.Rotation.UpVector * MedallionConstants::Highfive::HighfiveOffsetUpwards;
		SetActorLocation(FinalLocation);
		SetActorRotation(InBetweenTransform.Rotator());
	}
};