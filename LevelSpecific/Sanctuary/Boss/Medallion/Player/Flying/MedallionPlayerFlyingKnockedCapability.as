struct FMedallionPlayerKnockedCapabilityActivationParams
{
	float KnockedDirectionSign = 0.0;
}

class UMedallionPlayerFlyingKnockedCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerFlyingMovementComponent AirMoveDataComp;
	UMedallionPlayerAssetsComponent AssetsComp;

	TArray<FName> BoneNames;
	default BoneNames.Add(n"Spine38");
	default BoneNames.Add(n"Spine39");
	default BoneNames.Add(n"Spine40");
	default BoneNames.Add(n"Spine41");
	default BoneNames.Add(n"Spine42");
	default BoneNames.Add(n"Spine43");
	default BoneNames.Add(n"Spine44");
	default BoneNames.Add(n"Spine45");
	default BoneNames.Add(n"Spine46");
	default BoneNames.Add(n"Spine47");
	default BoneNames.Add(n"Spine48");

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		AirMoveDataComp = UMedallionPlayerFlyingMovementComponent::GetOrCreate(Owner);
		AssetsComp = UMedallionPlayerAssetsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerKnockedCapabilityActivationParams & ActivationParams) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
		if (Player.IsPlayerDead())
			return false;

		bool bKnockKnock = false;
#if !RELEASE
		if (SanctuaryMedallionHydraDevToggles::Players::FlyingAutoKnockPlayers.IsEnabled())
		{
			bKnockKnock = true;
			ActivationParams.KnockedDirectionSign = Math::Sign(AirMoveDataComp.SyncedSideways.Value) * -1.0;
		}
#endif
		TOptional<float> HydraKnockDirection = TryFindKnockingHydra();
		if (!HydraKnockDirection.IsSet())
			return false;

		ActivationParams.KnockedDirectionSign = HydraKnockDirection.Value * -1.0;
		return true;
	}

	TOptional<float> TryFindKnockingHydra() const
	{
		for (ASanctuaryBossMedallionHydra Hydra : RefsComp.Refs.Hydras)
		{
			if (Hydra.bDead)
				continue;

			float Diff = (RefsComp.Refs.MedallionBossPlane2D.ActorCenterLocation - Hydra.ActorLocation).Size();
			if (Diff > RefsComp.Refs.MedallionBossPlane2D.PlaneExtents.X * 3.0) // lodded away lolol
				continue;

			TOptional<FVector> HydraNeckClosestLocation = GetHydraNeckClosestLocation(Hydra);
			if (!HydraNeckClosestLocation.IsSet())
				continue;

			FVector ClosestNeckRelativeLocation = HydraNeckClosestLocation.Value - Player.ActorLocation;
			float ForwardDot = RefsComp.Refs.MedallionBossPlane2D.ActorForwardVector.DotProduct(ClosestNeckRelativeLocation);
			float SidewaysDot = RefsComp.Refs.MedallionBossPlane2D.ActorRightVector.DotProduct(ClosestNeckRelativeLocation);

			if (SanctuaryMedallionHydraDevToggles::Draw::KnockingHydra.IsEnabled())
			{
				FLinearColor Color = Player.GetPlayerUIColor();
				Color.A = 0.03;
				FVector Extents = FVector(MedallionConstants::Flying::KnockedRangeInFrontOfHydra, MedallionConstants::Flying::KnockedRangeSidewaysOfHydra,  MedallionConstants::Flying::KnockedRangeSidewaysOfHydra);
				Debug::DrawDebugSolidBox(HydraNeckClosestLocation.Value, Extents, RefsComp.Refs.MedallionBossPlane2D.ActorRotation, Color, 0.0, true);
			}

			if (ForwardDot > 0.0 && ForwardDot < MedallionConstants::Flying::KnockedRangeInFrontOfHydra &&
				Math::Abs(SidewaysDot) < MedallionConstants::Flying::KnockedRangeSidewaysOfHydra)
			{
				if (Math::IsNearlyEqual(SidewaysDot, 0.0, KINDA_SMALL_NUMBER))
					return TOptional<float>(Math::Sign(Math::Sign(AirMoveDataComp.SyncedSideways.Value) * -1.0)); // towards plane center
				return TOptional<float>(Math::Sign(SidewaysDot));
			}
		}

		return TOptional<float>();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < MedallionConstants::Flying::GetKnockedCooldown)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerKnockedCapabilityActivationParams ActivationParams)
	{
		AirMoveDataComp.AccKnockedAlpha.SnapTo(1.0);
		AirMoveDataComp.KnockRotationAlpha = 1.0;
		AirMoveDataComp.KnockedDirectionSign = ActivationParams.KnockedDirectionSign;

		AirMoveDataComp.AccKnockedIntoScreen.SnapTo(0.0, -20000);

		if (AssetsComp.KnockedByHydraEffect != nullptr)
			Player.PlayForceFeedback(AssetsComp.KnockedByHydraEffect, false, false, this);

		Player.DamagePlayerHealth(0.1);
	}

	TOptional<FVector> GetHydraNeckClosestLocation(ASanctuaryBossMedallionHydra Hydra) const
	{
		FVector PlayerLocation = Player.ActorLocation;

		TOptional<FVector> Closest;

		// which bones are we interested in?
		FTransform LastBoneTransform = Hydra.SkeletalMesh.GetBoneTransform(BoneNames[0]);
		for (int iBone = 1; iBone < BoneNames.Num(); ++iBone)
		{
			FTransform BoneTransform = Hydra.SkeletalMesh.GetBoneTransform(BoneNames[iBone]);
			if (PlayerLocation.Z > LastBoneTransform.Location.Z && PlayerLocation.Z < BoneTransform.Location.Z) // our height is between these bones. Let's find the closest location
			{
				float HeightDiffToPlayer = PlayerLocation.Z - LastBoneTransform.Location.Z;
				float HeightDiff = BoneTransform.Location.Z - LastBoneTransform.Location.Z;
				float Alpha = HeightDiffToPlayer / HeightDiff;
				FVector LocationAtPlayerHeight = Math::Lerp(LastBoneTransform.Location, BoneTransform.Location, Alpha);
				Closest.Set(LocationAtPlayerHeight);
				if (SanctuaryMedallionHydraDevToggles::Draw::KnockingHydra.IsEnabled())
				{
					Debug::DrawDebugLine(LastBoneTransform.Location, BoneTransform.Location, ColorDebug::White, 10, 0.0, true);
					Debug::DrawDebugSphere(LocationAtPlayerHeight, LineColor = Player.GetPlayerUIColor(), bDrawInForeground = true);			}
				else
				{
					break;
				}
			}
			else if (SanctuaryMedallionHydraDevToggles::Draw::KnockingHydra.IsEnabled())
			{
				Debug::DrawDebugLine(LastBoneTransform.Location, BoneTransform.Location, ColorDebug::Gray, 10, 0.0, true);
			}
			LastBoneTransform = BoneTransform;
		}

		return Closest;
	}
};