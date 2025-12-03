enum ECoastBossBoneName
{
	LeftTurret,
	RightTurret,
	LeftUpBarrel,
	RightUpBarrel,
	LeftDownBarrel,
	RightDownBarrel
}

struct FCoastBossAnimData
{
	const FName LeftTurretBoneName = n"LeftGunArm";
	const FName RightTurretBoneName = n"RightGunArm";
	const FName LeftUpBarrelBoneName = n"LeftUpperTurret";
	const FName RightUpBarrelBoneName = n"RightUpperTurret";
	const FName LeftDownBarrelBoneName = n"LeftLowerTurret";
	const FName RightDownBarrelBoneName = n"RightLowerTurret";

	private UHazeSkeletalMeshComponentBase Mesh;
	TMap<FName, FTransform> OriginalBoneRelativeTransforms;
	TMap<ECoastBossBoneName, FName> BoneNameMap;
	TMap<FName, float> BoneRecoilOffsets;
	TMap<FName, FRotator> TurretRelativeRotations;
	TOptional<FVector> LeftTurretWorldTarget;
	TOptional<FVector> RightTurretWorldTarget;
	float RotationInterpSpeed = 0.0;
	bool bInitialized = false;
	
	void Init(UHazeSkeletalMeshComponentBase In_Mesh)
	{
		Mesh = In_Mesh;
		InitBone(LeftTurretBoneName, ECoastBossBoneName::LeftTurret);
		InitBone(RightTurretBoneName, ECoastBossBoneName::RightTurret);
		InitBone(LeftUpBarrelBoneName, ECoastBossBoneName::LeftUpBarrel);
		InitBone(RightUpBarrelBoneName, ECoastBossBoneName::RightUpBarrel);
		InitBone(LeftDownBarrelBoneName, ECoastBossBoneName::LeftDownBarrel);
		InitBone(RightDownBarrelBoneName, ECoastBossBoneName::RightDownBarrel);
		bInitialized = true;
	}

	private void InitBone(FName BoneName, ECoastBossBoneName Enum)
	{
		OriginalBoneRelativeTransforms.Add(BoneName, GetBoneLocalTransform(BoneName));
		BoneRecoilOffsets.Add(BoneName, 0.0);
		BoneNameMap.Add(Enum, BoneName);

		if(Enum == ECoastBossBoneName::LeftTurret || Enum == ECoastBossBoneName::RightTurret)
		{
			TurretRelativeRotations.Add(BoneName, OriginalBoneRelativeTransforms[BoneName].Rotator());
		}
	}

	FTransform GetBoneLocalTransform(FName BoneName) const
	{
		return Mesh.GetSocketTransform(BoneName, ERelativeTransformSpace::RTS_ParentBoneSpace);
	}

	void SetTurretWorldTarget(FVector WorldTarget, ECoastBossBoneName Bone)
	{
		devCheck(IsTurretBone(Bone), "Can only set turret world target on right or left turret bones");
		if(Bone == ECoastBossBoneName::LeftTurret)
			LeftTurretWorldTarget.Set(WorldTarget);
		else if(Bone == ECoastBossBoneName::RightTurret)
			RightTurretWorldTarget.Set(WorldTarget);
	}

	void SetTurretRelativeRotation(FRotator RelativeRotation, ECoastBossBoneName Bone)
	{
		devCheck(IsTurretBone(Bone), "Can only set turret world target on right or left turret bones");
		FName BoneName = BoneNameMap[Bone];
		TurretRelativeRotations[BoneName] = RelativeRotation;
	}

	void ResetTurretRotation(ECoastBossBoneName Bone)
	{
		devCheck(IsTurretBone(Bone), "Can only reset turret world target on right or left turret bones");
		FName BoneName = BoneNameMap[Bone];
		TurretRelativeRotations[BoneName] = OriginalBoneRelativeTransforms[BoneName].Rotator();
		LeftTurretWorldTarget.Reset();
		RightTurretWorldTarget.Reset();
	}

	FRotator GetRelativeRotationToPointAtWorldTarget(FName Bone, FVector WorldTarget)
	{
		FName Parent = Mesh.GetParentBone(Bone);
		FVector TurretWorldLocation = Mesh.GetSocketLocation(Bone);
		FRotator WorldRotation = FRotator::MakeFromXZ(WorldTarget - TurretWorldLocation, FVector::UpVector);
		FTransform ParentTransform = Mesh.GetSocketTransform(Parent);
		return ParentTransform.InverseTransformRotation(WorldRotation);
	}

	void SetRecoilOffset(float Offset, ECoastBossBoneName Bone)
	{
		FName BoneName = BoneNameMap[Bone];
		BoneRecoilOffsets[BoneName] = Offset;
	}

	void GetCurrentBoneTransforms(TMap<FName, FTransform>&out OutBoneTransforms)
	{
		for(TMapIterator<FName, FTransform> Transform : OriginalBoneRelativeTransforms)
		{
			FTransform Tf = Transform.Value;
			if(Transform.Key == LeftTurretBoneName && LeftTurretWorldTarget.IsSet())
				Tf.SetRotation(GetRelativeRotationToPointAtWorldTarget(Transform.Key, LeftTurretWorldTarget.Value));
			else if(Transform.Key == RightTurretBoneName && RightTurretWorldTarget.IsSet())
				Tf.SetRotation(GetRelativeRotationToPointAtWorldTarget(Transform.Key, RightTurretWorldTarget.Value));
			else if(TurretRelativeRotations.Contains(Transform.Key))
				Tf.SetRotation(TurretRelativeRotations[Transform.Key]);

			Tf.Location = Tf.Location + (IsTurretBone(Transform.Key) ? Tf.Rotation.ForwardVector : Tf.Rotation.UpVector) * BoneRecoilOffsets[Transform.Key];
			OutBoneTransforms.Add(Transform.Key, Tf);
		}
	}

	bool IsTurretBone(FName Name) const
	{
		if(Name == LeftTurretBoneName)
			return true;

		if(Name == RightTurretBoneName)
			return true;

		return false;
	}

	bool IsTurretBone(ECoastBossBoneName Bone) const
	{
		if(Bone == ECoastBossBoneName::LeftTurret)
			return true;

		if(Bone == ECoastBossBoneName::RightTurret)
			return true;

		return false;
	}
}

namespace CoastBoss
{
	UFUNCTION()
	void CoastBossShowTutorialOnPlayers()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			auto AeronauticComp = UCoastBossAeronauticComponent::GetOrCreate(Player);
			AeronauticComp.ShowTutorial();
		}
	}
}