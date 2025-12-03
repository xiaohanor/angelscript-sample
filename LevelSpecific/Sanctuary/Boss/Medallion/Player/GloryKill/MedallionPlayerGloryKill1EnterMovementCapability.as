struct FMedallionPlayerGloryKill1EnterMovementParams
{
	ASanctuaryBossMedallionHydra AttackedHydra;
}

class UMedallionPlayerGloryKill1EnterMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 60;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerReferencesComponent RefsComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	FHazeAcceleratedVector AccRemovePlayerOffset;
	FHazeAcceleratedQuat AccRemovePlayerRotation;
	float SplineDistance = 0.0;

	const FVector LeftRelativeLoc = FVector(1354.120, -899.262, 4881.149);
	const FQuat LeftRelativeRot = FQuat(-0.084251589, -0.010402494, 0.992014596, 0.093276465).GetNormalized();
	const FVector RightRelativeLoc = FVector(1204.611, 1350.145, 4607.468);
	const FQuat RightRelativeRot = FQuat(-0.061308837, -0.111676868, 0.991480169, 0.027139987).GetNormalized();
	const float RemoveOffsetDuration = 0.5;

	FVector PlayerTargetRelativeLocation;
	FQuat PlayerTargetRelativeRotation;

	ASanctuaryBossMedallionHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMedallionPlayerGloryKill1EnterMovementParams & Params) const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::Enter)
			return false;
		if (GloryKillComp.GetCutsceneHydra() == nullptr)
			return false;
		Params.AttackedHydra = GloryKillComp.GetCutsceneHydra();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (Player.bIsControlledByCutscene)
		// 	return true;
		// if (Player.IsPlayerDead())
		// 	return true;
		// if (ActiveDuration > RemoveOffsetDuration)
		// 	return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMedallionPlayerGloryKill1EnterMovementParams Params)
	{
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, MedallionConstants::Tags::StrangleBlockPlayerFalling);
		Player.BlockCapabilities(n"Death", MedallionConstants::Tags::StrangleBlockPlayerFalling);

		GloryKillComp.SyncedStrangle.SetValue(0.0);
		
		GloryKillComp.bTetherToHydra = true;
		Hydra = Params.AttackedHydra;
		RefsComp.Refs.GloryKillCirclingSpotTemp.MedallionAppearAttach(Params.AttackedHydra);

		// todo, check and assign actual left / right and trigger different sequence maybe
		if (Player.IsMio())
		{
			PlayerTargetRelativeLocation = LeftRelativeLoc; 
			PlayerTargetRelativeRotation = LeftRelativeRot;
		}
		else
		{
			PlayerTargetRelativeLocation = RightRelativeLoc; 
			PlayerTargetRelativeRotation = RightRelativeRot;		
		}

		FTransform HipsTransform = Player.Mesh.GetSocketTransform(n"Hips");
		FVector HipsRelativeLocation = Hydra.ActorTransform.InverseTransformPosition(HipsTransform.Location);
		FQuat HipsRelativeRotation = Hydra.ActorTransform.InverseTransformRotation(HipsTransform.Rotation);

		AccRemovePlayerOffset.SnapTo(HipsRelativeLocation - PlayerTargetRelativeLocation);
		AccRemovePlayerRotation.SnapTo(FQuat::GetDelta(PlayerTargetRelativeRotation, HipsRelativeRotation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GloryKillComp.SetGloryKillState(EMedallionGloryKillState::EnterSequence, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// AccRemovePlayerOffset.AccelerateTo(FVector(), RemoveOffsetDuration, DeltaTime);
		// AccRemovePlayerRotation.AccelerateTo(FQuat(), RemoveOffsetDuration, DeltaTime);

		// FTransform HipsTransform = Player.Mesh.GetSocketTransform(n"Hips");
		// {
		// 	TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Loc", HipsTransform.Location);
		// 	TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Rot", HipsTransform.Rotation);
		// 	FVector HipsRelativeLocation = Hydra.ActorTransform.InverseTransformPosition(HipsTransform.Location);
		// 	FQuat HipsRelativeRotation = Hydra.ActorTransform.InverseTransformRotation(HipsTransform.Rotation);
		// 	TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Relative Loc", HipsRelativeLocation);
		// 	TEMPORAL_LOG(Player, "Strangle Sequence").Value("Hips Relative Rot", HipsRelativeRotation);
		// }

		// float Alpha = Math::Saturate(ActiveDuration / RemoveOffsetDuration);
		// FVector OffsetLocation = Math::EaseOut(AccRemovePlayerOffset.Value, FVector(), Alpha, 2);
		// FQuat OffsetRotation = FQuat::Slerp(AccRemovePlayerRotation.Value, FQuat(), Alpha);

		// FQuat WorldRotation = Hydra.ActorTransform.TransformRotation(FQuat::ApplyDelta(PlayerTargetRelativeRotation, OffsetRotation));
		// if (!MoveComp.PrepareMove(MoveData, WorldRotation.UpVector))
		// 	return;
		// FVector WorldLocation = Hydra.ActorTransform.TransformPosition(PlayerTargetRelativeLocation + OffsetLocation);

		// FVector Delta = WorldLocation - HipsTransform.Location;
		// MoveData.AddDelta(Delta);
		// MoveData.SetRotation(WorldRotation);
		// MoveComp.ApplyMove(MoveData);
	}
};