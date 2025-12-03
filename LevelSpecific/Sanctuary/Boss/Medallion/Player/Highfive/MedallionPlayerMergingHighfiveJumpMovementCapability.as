class UMedallionPlayerMergingHighfiveJumpMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1; // needs to be before all movement Capabilities
	default TickGroupSubPlacement = 11;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerAssetsComponent AssetsComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	FVector PlayerStartLocation;
	FHazeAcceleratedVector AccLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!HighfiveComp.IsHighfiveJumping())
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HighfiveComp.IsHighfiveJumping())
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (AssetsComp == nullptr)
			AssetsComp = UMedallionPlayerAssetsComponent::Get(Owner);
		PlayerStartLocation = Player.ActorLocation;
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
		if (AssetsComp.MedallionLocomotionFeature[Player] != nullptr)
			Player.AddLocomotionFeature(AssetsComp.MedallionLocomotionFeature[Player], this);

		Player.HealPlayerHealth(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.bIsControlledByCutscene)
			return;
		if (!MoveComp.PrepareMove(MoveData))
			return;

		float Alpha = Math::Saturate(ActiveDuration / HighfiveComp.GetHighfiveJumpDuration());

		FVector DestinationLocation = RefsComp.Refs.HighfiveTargetLocation.ActorCenterLocation;
		FVector OutwardsOffset;
		FVector LocationInBetween = (Player.ActorLocation + Player.OtherPlayer.ActorLocation) * 0.5;
		FTransform InBetweenTransform = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineWorldTransformToWorldLocation(LocationInBetween);	
		OutwardsOffset = InBetweenTransform.Rotation.RightVector * MedallionConstants::Highfive::HighfiveOffsetOutwards;
		DestinationLocation -= OutwardsOffset;

		const float SidewaysSign = Player.IsMio() ? 1 : -1;
		const FVector SidewaysOffset = RefsComp.Refs.HighfiveTargetLocation.ActorForwardVector * MedallionConstants::Highfive::HighfivePlayerSidewaysOffset * SidewaysSign;
		DestinationLocation += RefsComp.Refs.HighfiveTargetLocation.ActorForwardVector * SidewaysOffset;
		FVector CurrentLocation = Math::EaseOut(PlayerStartLocation, DestinationLocation, Alpha, 2.0);
		//FVector CurrentLocation = Math::Lerp(PlayerStartLocation, DestinationLocation, Alpha);
		CurrentLocation.Z = Math::EaseOut(PlayerStartLocation.Z, DestinationLocation.Z, Alpha, 4);
		CurrentLocation += Math::EaseOut(FVector(), OutwardsOffset, Alpha, 4);
	//	TargetLocation.Z += SanctuaryMedallionHighFiveExtraAltitudeCurve.GetFloatValue(Alpha) * MedallionConstants::Highfive::HighfiveJumpArcHeight; 

		if (SanctuaryMedallionHydraDevToggles::Draw::Highfive.IsEnabled())
		{
			if (Player.IsMio())
				Debug::DrawDebugSphere(RefsComp.Refs.HighfiveTargetLocation.ActorCenterLocation, 10, 12, ColorDebug::Carrot, bDrawInForeground = true);
			Debug::DrawDebugSphere(CurrentLocation, 30, 12, Math::Lerp(Player.GetPlayerUIColor(), ColorDebug::White, 0.5), bDrawInForeground = true);
		}

		if (HighfiveComp.bHighfiveSuccess)
			AccLocation.AccelerateTo(CurrentLocation, 5.0, DeltaTime);
		else
			AccLocation.SnapTo(CurrentLocation);

		FVector Delta = AccLocation.Value - Player.ActorLocation;
		MoveData.AddDelta(Delta);
		FVector FacingDirection = InBetweenTransform.Rotation.ForwardVector * SidewaysSign;
		MoveData.SetRotation(FRotator::MakeFromXZ(FacingDirection.GetSafeNormal(), FVector::UpVector));
		MoveComp.ApplyMove(MoveData);

		Player.RequestLocomotion(n"SanctuaryMedallionCombine", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearLocomotionFeatureByInstigator(this);
		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
		if (AssetsComp.MedallionLocomotionFeature[Player] != nullptr)
			Player.RemoveLocomotionFeature(AssetsComp.MedallionLocomotionFeature[Player], this);
	}
};