class UCentipedeSwingLandTargetComponent : UCentipedeSwingJumpTargetComponent
{
	default AdditionalVisibleRange = 2500.0;

	UPROPERTY(EditAnywhere, DisplayName = Mio, Meta = (MakeEditWidget))
	FTransform MioLandTransform;
	default MioLandTransform.SetLocation(FVector::LeftVector * 300);

	UPROPERTY(EditAnywhere, DisplayName = Zoe, Meta = (MakeEditWidget))
	private FTransform ZoeLandTransform;
	default ZoeLandTransform.SetLocation(FVector::RightVector * 300);

	// Evaluate landing target per-player with heuristics (i.e. distance)
	UPROPERTY(EditInstanceOnly)
	bool bUseContextualPlayerTarget = false;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (Query.DistanceToTargetable > ActivationRange)
			return false;

		Targetable::ApplyDistanceToScore(Query);
		Targetable::ApplyTargetableRange(Query, ActivationRange);

		return true;
	}

	FVector GetJumpImpulseForPlayer(AHazePlayerCharacter Player, float GravityMagnitude) const override
	{
		FVector TargetWorldLocation = Player.IsMio() ? GetMioTargetTransform().Location : GetZoeTargetTransform().Location;
		float Height = Math::Max(0.0, TargetWorldLocation.Z - Player.ActorLocation.Z) + Centipede::SwingJumpHeight;
		return Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, TargetWorldLocation, GravityMagnitude, Height);
	}

	FTransform GetMioTargetTransform() const
	{
		if (bUseContextualPlayerTarget)
		{
			// Just do furthest location, do fancier if needed (like velocity)
			FTransform MioFurthest = GetFurthestWorldTransformFromLocation(Game::Mio.ActorLocation);
			FTransform ZoeFurthest = GetFurthestWorldTransformFromLocation(Game::Zoe.ActorLocation);

			if (MioFurthest.Location.DistSquared(Game::Mio.ActorLocation) < ZoeFurthest.Location.DistSquared(Game::Zoe.ActorLocation))
				return MioFurthest;

			return GetClosestWorldTransformFromLocation(Game::Zoe.ActorLocation);

			// UPlayerCentipedeSwingComponent CentipedeSwingComponent = UPlayerCentipedeSwingComponent::Get(Game::Mio);
			// if (CentipedeSwingComponent.IsSwinging())
			// 	return GetFurthestWorldTransformFromLocation(Game::Mio.ActorLocation);

			// return GetClosestWorldTransformFromLocation(Game::Mio.ActorLocation);
		}

		return MioLandTransform * WorldTransform;
	}

	FTransform GetZoeTargetTransform() const
	{
		if (bUseContextualPlayerTarget)
		{
			// Just do furthest location, do fancier if needed (like velocity)
			FTransform MioFurthest = GetFurthestWorldTransformFromLocation(Game::Mio.ActorLocation);
			FTransform ZoeFurthest = GetFurthestWorldTransformFromLocation(Game::Zoe.ActorLocation);

			if (MioFurthest.Location.DistSquared(Game::Mio.ActorLocation) < ZoeFurthest.Location.DistSquared(Game::Zoe.ActorLocation))
				return GetClosestWorldTransformFromLocation(Game::Zoe.ActorLocation);

			return MioFurthest;

			// UPlayerCentipedeSwingComponent CentipedeSwingComponent = UPlayerCentipedeSwingComponent::Get(Game::Zoe);
			// if (CentipedeSwingComponent.IsSwinging())
			// 	return GetFurthestWorldTransformFromLocation(Game::Zoe.ActorLocation);

			// return GetClosestWorldTransformFromLocation(Game::Zoe.ActorLocation);
		}

		return ZoeLandTransform * WorldTransform;
	}

	FTransform GetFurthestWorldTransformFromLocation(FVector Location) const
	{
		FTransform MioWorldTransform = MioLandTransform * WorldTransform;
		FTransform ZoeWorldTransform = ZoeLandTransform * WorldTransform;

		if (MioWorldTransform.Location.DistSquared(Location) > ZoeWorldTransform.Location.DistSquared(Location))
			return MioWorldTransform;

		return ZoeWorldTransform;
	}

	FTransform GetClosestWorldTransformFromLocation(FVector Location) const
	{
		FTransform MioWorldTransform = MioLandTransform * WorldTransform;
		FTransform ZoeWorldTransform = ZoeLandTransform * WorldTransform;

		if (MioWorldTransform.Location.DistSquared(Location) < ZoeWorldTransform.Location.DistSquared(Location))
			return MioWorldTransform;

		return ZoeWorldTransform;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Editor::IsCooking())
			return;

		auto Mesh = UPoseableMeshComponent::Create(Owner);
		Mesh.AttachTo(Owner.RootComponent, NAME_None, EAttachLocation::SnapToTarget);
		Mesh.bIsEditorOnly = true;
		Mesh.IsVisualizationComponent = true;
		Mesh.SetComponentTickEnabled(false);
		Mesh.SetHiddenInGame(true);

		USkeletalMesh SkelMesh = Cast<USkeletalMesh>(Editor::LoadAsset(n"/Game/Characters/Sanctuary/Centipede/Centipede.Centipede"));
		Mesh.SetSkinnedAssetAndUpdate(SkelMesh);

		for (int i = 0; i < BoneWhitelist.Num(); i++)
		{
			float Alpha = Math::Saturate(float(i) / (BoneWhitelist.Num() - 1));
			FVector Location = Math::Lerp(MioLandTransform.Location, ZoeLandTransform.Location, Alpha) + FVector::UpVector * 100;
			Mesh.SetBoneLocationByName(BoneWhitelist[i], Location, EBoneSpaces::ComponentSpace);

			if (i == 0)
				Mesh.SetBoneRotationByName(BoneWhitelist[i], MioLandTransform.Rotator(), EBoneSpaces::ComponentSpace);
			else if (i == BoneWhitelist.Num() - 1)
				Mesh.SetBoneRotationByName(BoneWhitelist[i], ZoeLandTransform.Rotator(), EBoneSpaces::ComponentSpace);
			else
			{
				FQuat Rotation = FQuat::MakeFromX(MioLandTransform.Location - ZoeLandTransform.Location);
				Mesh.SetBoneRotationByName(BoneWhitelist[i], Rotation.Rotator(), EBoneSpaces::ComponentSpace);
			}
		}

		Mesh.ForceRefreshBoneTransforms();
	}

	// Taken from Centipede's ABP
	TArray<FName> BoneWhitelist;
	default BoneWhitelist.AddUnique(n"FrontCharacterRoot");
	default BoneWhitelist.AddUnique(n"Segment1");
	default BoneWhitelist.AddUnique(n"Segment2");
	default BoneWhitelist.AddUnique(n"Segment3");
	default BoneWhitelist.AddUnique(n"Segment4");
	default BoneWhitelist.AddUnique(n"Segment5");
	default BoneWhitelist.AddUnique(n"Segment6");
	default BoneWhitelist.AddUnique(n"Segment7");
	default BoneWhitelist.AddUnique(n"Segment8");
	default BoneWhitelist.AddUnique(n"Segment9");
	default BoneWhitelist.AddUnique(n"Segment10");
	default BoneWhitelist.AddUnique(n"Segment11");
	default BoneWhitelist.AddUnique(n"BackCharacterRoot");
	
#endif
}