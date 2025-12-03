namespace SpearSettings
{
	const int NumSpears = 16;

	const float AccOutDuration = 1.0;
	const float AccInDuration = 1.0;
	const float MoveOutDist = 200;
	
	const float ToggleDirectionInterval = 2.0;
}

struct FSummitDecimatorTopdownAnimSpear
{
	UPoseableMeshComponent PoseableMesh;

	FName SocketName = NAME_None;
	
	FVector ExposedSpineRelativeLocation;
	FVector WithdrawnSpineRelativeLocation;
	FHazeAcceleratedFloat AccMove;

	void SnapWithdrawSpear()
	{
		AccMove.SnapTo(0.0);
		PoseableMesh.SetBoneLocationByName(SocketName, WithdrawnSpineRelativeLocation, EBoneSpaces::ComponentSpace);
	}
	
	void SnapExposeSpear()
	{
		AccMove.SnapTo(SpearSettings::MoveOutDist);
		PoseableMesh.SetBoneLocationByName(SocketName, ExposedSpineRelativeLocation, EBoneSpaces::ComponentSpace);
	}

	void ExposeSpear(const float DeltaTime, float SpeedFactor, float DistFactor = 1.0)
	{
		const float MoveOutDist = SpearSettings::MoveOutDist * DistFactor;
		float Duration = SpearSettings::AccOutDuration;
		AccMove.AccelerateTo(MoveOutDist, Duration , DeltaTime * SpeedFactor);
	}

	void WithdrawSpear(const float DeltaTime, float SpeedFactor)
	{
		float Duration = SpearSettings::AccInDuration;
		AccMove.AccelerateTo(0.0, Duration, DeltaTime * SpeedFactor);
	}

	void UpdatePoseableMeshLocation()
	{
		FVector RefLocation = PoseableMesh.GetBoneLocationByName(n"Spine", EBoneSpaces::ComponentSpace);
		const FRotator LocalRotation = PoseableMesh.GetBoneRotationByName(SocketName, EBoneSpaces::ComponentSpace);
		const FVector MoveToLocation = RefLocation + WithdrawnSpineRelativeLocation + (LocalRotation.UpVector * AccMove.Value);
		PoseableMesh.SetBoneLocationByName(SocketName, MoveToLocation, EBoneSpaces::ComponentSpace);
	}
}

class USummitDecimatorTopdownSpearAnimCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 120;
	
	UHazeMovementComponent MoveComp;
	UPoseableMeshComponent PoseableMesh;
	UHazeCharacterSkeletalMeshComponent Mesh;
	UHazeActorRespawnableComponent RespawnComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;

	TArray<FSummitDecimatorTopdownAnimSpear> Spears;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		PoseableMesh = UPoseableMeshComponent::Get(Owner);
		Mesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		// Get all Spears
		if (PoseableMesh != nullptr)
		{
			Spears.Reserve(SpearSettings::NumSpears);
			AddSpear(n"LeftBackCenterSpear");
			AddSpear(n"LeftLowerBackSpear");
			AddSpear(n"LeftUpperBackSpear");
			AddSpear(n"RightBackCenterSpear");
			AddSpear(n"RightLowerBackSpear");
			AddSpear(n"RightUpperBackSpear");
			AddSpear(n"LeftCenterFrontSpear");
			AddSpear(n"LeftLowerFrontSpear");
			AddSpear(n"LeftLowerMiddleSpear");
			AddSpear(n"LeftUpperFrontSpear");
			AddSpear(n"LeftUpperMiddleSpear");
			AddSpear(n"RightCenterFrontSpear");
			AddSpear(n"RightLowerFrontSpear");
			AddSpear(n"RightLowerMiddleSpear");
			AddSpear(n"RightUpperFrontSpear");
			AddSpear(n"RightUpperMiddleSpear");

			SnapExposeSpears();
		}
	}

	UFUNCTION()
	private void OnReset()
	{
		if (PoseableMesh != nullptr)
		{
			SnapWithdrawSpears();
		}
	}

	private void AddSpear(FName BoneName)
	{
		FSummitDecimatorTopdownAnimSpear Spear;
		Spear.PoseableMesh = PoseableMesh;
		Spear.SocketName = BoneName;
		FVector RefLocation = PoseableMesh.GetBoneLocationByName(n"Spine", EBoneSpaces::ComponentSpace);
		Spear.ExposedSpineRelativeLocation = PoseableMesh.GetBoneLocationByName(Spear.SocketName, EBoneSpaces::ComponentSpace) - RefLocation;
		Spear.WithdrawnSpineRelativeLocation = Spear.ExposedSpineRelativeLocation - (PoseableMesh.GetBoneRotationByName(Spear.SocketName, EBoneSpaces::ComponentSpace).UpVector * SpearSettings::MoveOutDist);
		Spears.Add(Spear);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PoseableMesh == nullptr)
			return false;
		if (PhaseComp.CurrentState == ESummitDecimatorState::PermaKnockedOut)
			return false;
		if (PhaseComp.CurrentState == ESummitDecimatorState::PreBattleStart)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PoseableMesh == nullptr)
			return true;
		if (PhaseComp.CurrentState == ESummitDecimatorState::PermaKnockedOut)
			return true;
		if (PhaseComp.CurrentState == ESummitDecimatorState::PreBattleStart)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive())
			PoseableMesh.CopyPoseFromSkeletalComponent(Mesh);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Mesh.SetHiddenInGame(true);
		Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

		PoseableMesh.SetHiddenInGame(false);
		PoseableMesh.CopyPoseFromSkeletalComponent(Mesh); // this will lag one frame behind
		//Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"AnimEvalComplete"); // this will fix frame lag
	}
	
	// UFUNCTION()
	// private void AnimEvalComplete(UHazeSkeletalMeshComponentBase SkelMeshComp)
	// {
	// 	PoseableMesh.CopyPoseFromSkeletalComponent(Mesh);
		
	// 	// And update bone transforms here.
	// }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mesh.SetHiddenInGame(false);		
		PoseableMesh.SetHiddenInGame(true);
	}

	bool bIsWithdrawingSpears = true;
	float Timer = 0.0;
	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
#if EDITOR
		if (bIsTesting)
		{
			TestSpearToggle(DeltaTime);
			return;
		}
#endif
		PoseableMesh.CopyPoseFromSkeletalComponent(Mesh);

		if (PhaseComp.CurrentState == ESummitDecimatorState::PermaKnockedOut)
		{
			SnapWithdrawSpears();
			return;
		}

		float SpeedFactor = 1.0;
		float DistFactor = 1.0;
		if (PhaseComp.CurrentState == ESummitDecimatorState::KnockedOutRecover || PhaseComp.CurrentState == ESummitDecimatorState::TakingRollHitDamage)
		{
			SpeedFactor = 0.5;
			DistFactor = 1.5;
		}
		else if (PhaseComp.CurrentState == ESummitDecimatorState::KnockedOut || PhaseComp.CurrentState == ESummitDecimatorState::PermaKnockedOut)
		{
			SpeedFactor = 0.1;
			DistFactor = 1.5;
		}
		else if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::ChargingAndSpawningSpikeBombs)
		{
			SpeedFactor = 4.0;
			DistFactor = 1.5;
		}


		Timer += DeltaTime;
		if (Timer > (SpearSettings::ToggleDirectionInterval/SpeedFactor))
		{
			bIsWithdrawingSpears = !bIsWithdrawingSpears;
			Timer -= (SpearSettings::ToggleDirectionInterval/SpeedFactor);
			Spears.Shuffle();
		}
		
		if (bIsWithdrawingSpears)
			WithdrawSpears(DeltaTime, SpeedFactor);
		else
			ExposeSpears(DeltaTime, SpeedFactor, DistFactor);
	}

	void SnapWithdrawSpears()
	{
		for (FSummitDecimatorTopdownAnimSpear& Spear : Spears)
		{
			Spear.SnapWithdrawSpear();
		}
	}

	void SnapExposeSpears()
	{
		for (FSummitDecimatorTopdownAnimSpear& Spear : Spears)
		{
			Spear.SnapExposeSpear();
		}
	}

	void ExposeSpears(const float DeltaTime, const float SpeedFactor = 1.0, float DistFactor = 1.0)
	{
		for (int i = 0; i < Spears.Num(); i++)
		{
			if (Timer > i * (SpearSettings::ToggleDirectionInterval / SpeedFactor) / SpearSettings::NumSpears)
				Spears[i].ExposeSpear(DeltaTime, SpeedFactor, DistFactor);

			Spears[i].UpdatePoseableMeshLocation();
		}
	}

	void WithdrawSpears(const float DeltaTime, const float SpeedFactor = 1.0)
	{
		for (int i = 0; i < Spears.Num(); i++)
		{
			if (Timer > i * (SpearSettings::ToggleDirectionInterval / SpeedFactor) / SpearSettings::NumSpears)
				Spears[i].WithdrawSpear(DeltaTime, SpeedFactor);

			Spears[i].UpdatePoseableMeshLocation();
		}
	}

#if EDITOR
	bool bIsTesting = false;
	bool bIsExposingSpears = false;
	UFUNCTION(DevFunction)
	void ToggleSpears()
	{
		bIsTesting = true;
		bIsExposingSpears = !bIsExposingSpears;
	}

	void TestSpearToggle(const float DeltaTime)
	{
		if (bIsExposingSpears)
		{
			ExposeSpears(DeltaTime);
		}
		else
		{
			WithdrawSpears(DeltaTime);
		}
	}
#endif
}