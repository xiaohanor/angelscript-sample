struct FSkylineBossTankCrusherBlastAttackActivateParams
{
	AHazePlayerCharacter TargetPlayer;
};

class USkylineBossTankCrusherBlastAttackCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);
	default CapabilityTags.Add(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusher);
	default CapabilityTags.Add(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusherBlast);

	USkylineBossTankCrusherComponent CrusherComp;
	UDecalComponent Decal;
	UMaterialInstanceDynamic DecalMID;

	AHazePlayerCharacter TargetPlayer;

	bool bHasFiredBlast = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		CrusherComp = USkylineBossTankCrusherComponent::Get(Owner);
		Decal = UDecalComponent::Create(Owner);
		DecalMID = Material::CreateDynamicMaterialInstance(Decal, CrusherComp.BlastTelegraphDecal);
		Decal.DecalMaterial = DecalMID;

		Decal.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Decal.DestroyComponent(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankCrusherBlastAttackActivateParams& Params) const
	{
//		if (!BossTank.IsAnyCapabilityActive(SkylineBossTankTags::SkylineBossTankChase))
//			return false;

//		if (BossTank.State.Get() != ESkylineBossTankState::Chasing)
//			return false;

		if (DeactiveDuration < 2.0)
			return false;

		if (!BossTank.HasAttackTarget())
			return false;

		Params.TargetPlayer = Cast<AHazePlayerCharacter>(BossTank.GetBikeFromTarget(BossTank.GetAttackTarget()).GetDriver());

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 2.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankCrusherBlastAttackActivateParams Params)
	{
		TargetPlayer = Params.TargetPlayer;
		bHasFiredBlast = false;

		CrusherComp.PlayTelegraph();

		CrusherComp.ArmRotationTarget = 1.0;

		Decal.SetHiddenInGame(false);

		Decal.SetWorldScale3D(FVector(3.0, 4.0, 3.0));

/*
		auto BlastProjectile = SpawnActor(CrusherComp.BlastProjectileClass, bDeferredSpawn = true);
//		BlastProjectile.AttachToActor(BossTank, AttachmentRule = EAttachmentRule::KeepWorld);
		BlastProjectile.BossTank = BossTank;
		BlastProjectile.AddTickPrerequisiteActor(Owner);
//		BlastProjectile.ActorLocation = CrusherComp.WorldLocation;
//		BlastProjectile.ActorQuat = BossTank.ActorQuat;
//		BlastProjectile.AccQuat.SnapTo(BossTank.ActorQuat);
	
		FTransform Transform;
		Transform.Location = CrusherComp.WorldLocation;
		Transform.Rotation = BossTank.ActorQuat;

		FinishSpawningActor(BlastProjectile, Transform);
*/
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrusherComp.ArmRotationTarget = 0.0;

		Decal.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && !bHasFiredBlast && ActiveDuration > 0.8)
		{
			const FVector Location = FVector(CrusherComp.WorldLocation.X, CrusherComp.WorldLocation.Y, BossTank.ActorLocation.Z);
			const FQuat Rotation = BossTank.ActorQuat;
			CrumbSpawnShockwave(Location, Rotation);
		}

		if (TargetPlayer != nullptr)
		{
			FVector TargetToBoss = TargetPlayer.ActorLocation - BossTank.ActorLocation;
			FVector BossViewDirection = TargetPlayer.ViewLocation - BossTank.ActorLocation;
			float BossViewDot = TargetPlayer.ViewRotation.ForwardVector.DotProduct(BossViewDirection.SafeNormal);

			FVector RelativeLocationToBoss = BossTank.ActorTransform.InverseTransformPositionNoScale(TargetPlayer.ActorLocation);
			bool bInFrontOfBoss = (RelativeLocationToBoss.X > 0.0 && RelativeLocationToBoss.Y < 1000.0 && RelativeLocationToBoss.Y > -1000.0);

//			PrintToScreen("ViewDot: " + BossViewDot, 0.0, FLinearColor::Red);
			
			DecalMID.SetScalarParameterValue(n"Opacity", Math::Max(0.0, BossViewDot * (bInFrontOfBoss ? 1.0 : 0.0)));
			Decal.WorldLocation = FVector(TargetPlayer.ActorLocation.X, TargetPlayer.ActorLocation.Y, BossTank.ActorLocation.Z);
			Decal.WorldRotation = FRotator::MakeFromZX(TargetToBoss.VectorPlaneProject(FVector::UpVector).SafeNormal, FVector::UpVector);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnShockwave(FVector Location, FQuat Rotation)
	{
		auto BlastProjectile = SpawnActor(CrusherComp.BlastProjectileClass, bDeferredSpawn = true);
		BlastProjectile.BossTank = BossTank;
		BlastProjectile.AddTickPrerequisiteActor(Owner);

		FinishSpawningActor(BlastProjectile, FTransform(Rotation, Location));

		bHasFiredBlast = true;
	}
};