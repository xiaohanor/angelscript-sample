class UMedallionMedallionHoverCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	AMedallionMedallionActor Medallion;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UHazeSplineComponent SidescrollerSpline;
	AHazePlayerCharacter Player;

	FHazeAcceleratedFloat AccHighfive;

	const float DistanceToSplit = 1600.0;

	const float CloseDistance = 10000.0;
	const float HighfiveDistance = 5000.0;

	const float StartMergeDistance = 500.0;
	const float EndMergeDistance = 200.0;

	bool bSnappedOffset = false;
	FHazeAcceleratedVector AccRemoveOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
		Player = Game::GetPlayer(Medallion.TargetPlayer);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.SideScrollerSplineLocker == nullptr)
			return false;
		if (Medallion.MedallionState != EMedallionMedallionState::HoverTowardsOther)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs == nullptr)
			return true;
		if (RefsComp.Refs.SideScrollerSplineLocker == nullptr)
			return true;
		if (Medallion.MedallionState != EMedallionMedallionState::HoverTowardsOther)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Medallion.CinematicSkelMeshBase.ResetAllAnimation(true);
		Medallion.AttachToComponent(Player.Mesh, Medallion.ChestAttachSocket, EAttachmentRule::SnapToTarget); //

		SidescrollerSpline = RefsComp.Refs.SideScrollerSplineLocker.Spline;
		Medallion.VisibleInstigators.Add(this);
		bSnappedOffset = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Medallion.VisibleInstigators.Remove(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float PlayerSplineDist = SidescrollerSpline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float OtherPlayerSplineDist = SidescrollerSpline.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);

		float OtherPlayerRelativeSplineDist = PlayerSplineDist - OtherPlayerSplineDist;
		float ClampedOtherPlayerRelativeSplineDistance = Math::Clamp(OtherPlayerRelativeSplineDist, DistanceToSplit * -2.0, DistanceToSplit * 2.0);
		float OtherPlayerRelativeHeight = Player.OtherPlayer.ActorLocation.Z - Player.ActorLocation.Z;

		FVector ClosestSplineLocation = SidescrollerSpline.GetWorldLocationAtSplineDistance(PlayerSplineDist);
		FVector OtherPlayerClampedRelativeSplineLocation = SidescrollerSpline.GetWorldLocationAtSplineDistance(PlayerSplineDist - ClampedOtherPlayerRelativeSplineDistance)
															+ FVector::UpVector * OtherPlayerRelativeHeight;

		FVector MedallionForward = (OtherPlayerClampedRelativeSplineLocation - ClosestSplineLocation).GetSafeNormal();
		FVector DesiredMedallionLocation = Medallion.ActorLocation + MedallionForward * 50.0;

		if (SanctuaryMedallionHydraDevToggles::Draw::Amulet.IsEnabled())
			Debug::DrawDebugSphere(DesiredMedallionLocation, 5.0, 12, ColorDebug::Ruby);

		if (!bSnappedOffset)
		{
			bSnappedOffset = true;
			AccRemoveOffset.SnapTo(DesiredMedallionLocation - Medallion.ActorLocation);
		}
		else
			AccRemoveOffset.AccelerateTo(FVector(), 1.0, DeltaTime);

		float Signwards = Player.IsMio() ? -1.0 : 1.0 ;
		Medallion.RemoveOffsetsBetweenStatesRoot.SetWorldRotation(FRotator::MakeFromYZ(MedallionForward * Signwards, Player.ActorUpVector));
		Medallion.RemoveOffsetsBetweenStatesRoot.SetWorldLocation(DesiredMedallionLocation + AccRemoveOffset.Value);

		//Set opacity based on distance
		float MedallionDistance = Game::Mio.GetDistanceTo(Game::Zoe);

		// PrintToScreenScaled("" + Opacity);

		if (Medallion.OtherMedallionActor != nullptr)
		{
			float MergeAlpha = 0.0;
			float Distance = Medallion.ActorLocation.Distance(Medallion.OtherMedallionActor.ActorLocation);
			MergeAlpha = Math::GetMappedRangeValueClamped(
				FVector2D(StartMergeDistance, EndMergeDistance), 
				FVector2D(0.0, 1.0), 
				Distance);
			if (HighfiveComp.IsInHighfiveSuccess())
			{
				AccHighfive.ThrustTo(1.0, 100.0, DeltaTime);
			}
			else
			{
				AccHighfive.AccelerateTo(HighfiveComp.HighfiveHoldAlpha * 0.95, 0.25, DeltaTime);
			}

			MergeAlpha = AccHighfive.Value;
			FVector AverageLocation = (Medallion.ActorLocation + Medallion.OtherMedallionActor.ActorLocation) * 0.5;
			FVector MergedLocation = Math::Lerp(DesiredMedallionLocation, AverageLocation, MergeAlpha);
			if (SanctuaryMedallionHydraDevToggles::Draw::Amulet.IsEnabled())
				Debug::DrawDebugSphere(Medallion.RemoveOffsetsBetweenStatesRoot.WorldLocation, 10.0, 12, ColorDebug::White);

			Medallion.RemoveOffsetsBetweenStatesRoot.SetWorldLocation(MergedLocation);
			Medallion.bMergReady = MergeAlpha >= 1.0 - KINDA_SMALL_NUMBER;
			if (Medallion.bMergReady && Medallion.OtherMedallionActor.bMergReady && !Medallion.bMerged && !Medallion.OtherMedallionActor.bMerged)
			{
				Medallion.bMerged = true;
				Medallion.OtherMedallionActor.bMerged = true;
				Medallion.BP_MedallionReunited();
				Medallion.OtherMedallionActor.BP_MedallionReunited();
			}
		}
	}
};