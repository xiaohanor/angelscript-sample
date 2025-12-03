enum ESummitEggBeastState
{
	None,
	ChaseStart,
	OnGround,
	FlyMountain,
	OnMountain,
	FlyOffMountain,
	WallRun
}

enum ESummitEggBeastActionState
{
	None,
	Shooting,
}

struct FSummitEggBeastShootActivatedParams
{
	AHazePlayerCharacter TargetPlayer;
	FTransform StartTransform;
	FVector TargetLocation;
	FVector TargetGroundLocation;
	bool bTargetAirLocation;
	bool bHadValidTarget;
}

struct FSummitEggBeastPlayerGroundData
{
	bool bWasGrounded = false;
	FVector GroundLocation;
}

class UAnimNotifySummitEggBeastShoot : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp == nullptr)
			return false;

		auto EggBeast = Cast<ASummitEggStoneBeast>(MeshComp.Owner);
		if (EggBeast == nullptr)
			return false;

		EggBeast.bIsReadyToShoot = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "EggBeastShoot";
	}
}

class USummitEggBeastShootActionCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitEggStoneBeast EggBeast;

	int ProjectileCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		EggBeast = Cast<ASummitEggStoneBeast>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitEggBeastShootActivatedParams& Params) const
	{
		if (!EggBeast.bIsReadyToShoot)
			return false;

		// Get Player furthest back along spline
		AHazePlayerCharacter Target;
		float MioSplineDist = EggBeast.PlayerPositionSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorCenterLocation);
		float ZoeSplineDist = EggBeast.PlayerPositionSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorCenterLocation);
		if (MioSplineDist < ZoeSplineDist)
			Target = Game::Mio;
		else
			Target = Game::Zoe;

		if (!EggBeast.IsPlayerValid(Target))
		{
			if (!EggBeast.IsPlayerValid(Target.OtherPlayer))
				return false;
			else
				Target = Target.OtherPlayer;
		}
		Params.StartTransform = EggBeast.SkelMesh.GetBoneTransform(EggBeast.ShootBone);
		Params.bHadValidTarget = true;
		Params.TargetPlayer = Target;
		Params.TargetLocation = Target.ActorLocation;
		Params.TargetGroundLocation = EggBeast.PlayerGroundData[Target].GroundLocation;
		Params.bTargetAirLocation = !EggBeast.PlayerGroundData[Target].bWasGrounded;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSummitEggBeastShootActivatedParams& Params) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitEggBeastShootActivatedParams Params)
	{
		if (Params.bHadValidTarget)
		{
			AHazePlayerCharacter Target = Params.TargetPlayer;
			FVector TargetLocation = Params.TargetLocation;
			bool bTargetAirLocation = Params.bTargetAirLocation;
			if (!bTargetAirLocation)
			{
				TargetLocation = Params.TargetGroundLocation;
			}

			EggBeast.ShootProjectile(Params.StartTransform, TargetLocation, bTargetAirLocation);
		}

		EggBeast.bIsReadyToShoot = false;
	}
}

struct FSummitEggStoneBeastStateData
{
	FSummitEggStoneBeastStateData(ESummitEggBeastState InState)
	{
		State = InState;
		switch (State)
		{
			case ESummitEggBeastState::None:
				Priority = 0;
				break;
			case ESummitEggBeastState::ChaseStart:
				Priority = 10;
				break;
			case ESummitEggBeastState::OnGround:
				Priority = 20;
				break;
			case ESummitEggBeastState::FlyMountain:
				Priority = 30;
				break;
			case ESummitEggBeastState::OnMountain:
				Priority = 40;
				break;
			case ESummitEggBeastState::FlyOffMountain:
				Priority = 50;
				break;
			case ESummitEggBeastState::WallRun:
				Priority = 60;
				break;
		}
	}
	ESummitEggBeastState State;
	int Priority;
	int opCmp(FSummitEggStoneBeastStateData Other) const
	{
		if (Priority >= Other.Priority)
			return 1;
		else
			return -1;
	}
}

class ASummitEggStoneBeast : AHazeActor
{
	access Internal = private, USummitEggBeastShootActionCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshPivotComp;

	UPROPERTY(DefaultComponent, Attach = "MeshPivotComp")
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = "SkelMesh")
	USceneComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	FName ShootBone = n"Tongue5";
	
#if EDITOR
	UPROPERTY(EditDefaultsOnly)
	TArray<UAnimSequence> EditorPreviewAnimSequences;

	UPROPERTY(EditAnywhere)
	bool bPreviewAnimation = true;

	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "30.0", UIMin = "0.0", UIMax = "30.0", Delta = "0.1"))
	float EditorPreviewAnimTime = 0.0;

	UPROPERTY(EditAnywhere, meta = (GetOptions = "GetEditorPreviewSequenceNames"))
	FName EditorPreviewAnim;

	UFUNCTION()
	TArray<FName> GetEditorPreviewSequenceNames() const
	{
		TArray<FName> Names;
		Names.Reserve(EditorPreviewAnimSequences.Num());
		for (auto AnimSequence : EditorPreviewAnimSequences)
		{
			if (AnimSequence == nullptr)
				continue;

			Names.Add(AnimSequence.Name);
		}
		return Names;
	}

	UAnimSequence EditorGetSequenceFromName(FName AnimName)
	{
		for (auto AnimSequence : EditorPreviewAnimSequences)
		{
			if (AnimSequence.Name.IsNone())
				continue;

			if (AnimSequence.Name == AnimName)
				return AnimSequence;
		}
		return nullptr;
	}
#endif

	UPROPERTY()
	TSubclassOf<ASummitEggBeastProjectile> ProjectileClass;

	UPROPERTY()
	bool bIsActive;

	UPROPERTY(EditAnywhere)
	ASplineActor PlayerPositionSpline;

	access:Internal ESummitEggBeastActionState ActionState;

	TArray<FInstigator> MioTargetInstigators;
	TArray<FInstigator> ZoeTargetInstigators;
	AHazePlayerCharacter CurrentPlayerTarget;

	TArray<FSummitEggStoneBeastStateData> AppliedStates;

	bool bIsReadyToShoot = false;
	TPerPlayer<UPlayerMovementComponent> PlayerMoveComps;
	TPerPlayer<FSummitEggBeastPlayerGroundData> PlayerGroundData;

	uint ProjectileCount;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (!EditorPreviewAnim.IsNone() && bPreviewAnimation)
		{
			SkelMesh.EditorPreviewAnim = EditorGetSequenceFromName(EditorPreviewAnim);
			SkelMesh.EditorPreviewAnimTime = EditorPreviewAnimTime;
		}
		else if (!bPreviewAnimation)
		{
			SkelMesh.EditorPreviewAnim = nullptr;
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentPlayerTarget = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ActionState == ESummitEggBeastActionState::Shooting)
		{
			for (auto Player : Game::Players)
			{
				if (PlayerMoveComps[Player].HasGroundContact())
				{
					PlayerGroundData[Player].GroundLocation = PlayerMoveComps[Player].GroundContact.ImpactPoint;
					PlayerGroundData[Player].bWasGrounded = true;
				}
				else
				{
					FHazeTraceSettings PlayerTraceSettings;
					PlayerTraceSettings.TraceWithPlayer(Player);
					// PlayerTraceSettings.DebugDrawOneFrame();
					auto Result = PlayerTraceSettings.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation + FVector::DownVector * 300);
					if (Result.bBlockingHit)
					{
						PlayerGroundData[Player].GroundLocation = Result.Location;
						PlayerGroundData[Player].bWasGrounded = true;
					}
					else
					{
						PlayerGroundData[Player].bWasGrounded = false;
					}
				}
			}
		}

#if EDITOR
		TEMPORAL_LOG(this).Value("Current State", GetState());
		auto StateSection = TEMPORAL_LOG(this).Section("States");

		for (int i = 0; i < AppliedStates.Num(); i++)
		{
			auto SubSection = StateSection.Section(f"{i}");
			SubSection.Value(f"Value", AppliedStates[i].State);
			SubSection.Value(f"Priority", AppliedStates[i].Priority);
		}

		auto MioSection = TEMPORAL_LOG(this).Section("MioInstigators");
		for (int i = 0; i < MioTargetInstigators.Num(); i++)
		{
			MioSection.Value(f"MioTargetInstigators{i}", MioTargetInstigators[i].ToString());
		}

		auto ZoeSection = TEMPORAL_LOG(this).Section("ZoeInstigators");
		for (int i = 0; i < ZoeTargetInstigators.Num(); i++)
		{
			ZoeSection.Value(f"ZoeTargetInstigators{i}", ZoeTargetInstigators[i].ToString());
		}
#endif
	}

	void ShootProjectile(FTransform StartTransform, FVector EndLocation, bool bDestroyWhenReachEnd, float MoveDuration = 2.0)
	{
		auto Projectile = SpawnActor(ProjectileClass, StartTransform.Location, StartTransform.Rotator(), NAME_None, true);
		Projectile.Initialize(StartTransform.Location, EndLocation, bDestroyWhenReachEnd, MoveDuration);
		FinishSpawningActor(Projectile);
		Projectile.MakeNetworked(this, ProjectileCount);
		ProjectileCount++;
	}

	bool IsPlayerValid(AHazePlayerCharacter Player)
	{
		bool bPlayerAlive = !Player.IsPlayerDead() && !Player.IsPlayerRespawning();
		if (Player.IsMio())
			return MioTargetInstigators.Num() > 0 && bPlayerAlive;
		else
			return ZoeTargetInstigators.Num() > 0 && bPlayerAlive;
	}

	int GetTotalInstigatorCount()
	{
		return MioTargetInstigators.Num() + ZoeTargetInstigators.Num();
	}

	void AddPlayerTargetInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (Player.IsMio())
			MioTargetInstigators.AddUnique(Instigator);
		else
			ZoeTargetInstigators.AddUnique(Instigator);
	}

	void RemovePlayerTargetInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (Player.IsMio() && MioTargetInstigators.Contains(Instigator))
			MioTargetInstigators.Remove(Instigator);
		else if (Player.IsZoe() && ZoeTargetInstigators.Contains(Instigator))
			ZoeTargetInstigators.Remove(Instigator);
	}

	UFUNCTION()
	void ActivateStoneBeast(ESummitEggBeastState State)
	{
		ApplyState(State);
		if (bIsActive)
			return;

		bIsActive = true;
	}

	UFUNCTION(DevFunction)
	void ApplyState(ESummitEggBeastState NewState)
	{
		AppliedStates.AddUnique(FSummitEggStoneBeastStateData(NewState));
		AppliedStates.Sort();
	}

	UFUNCTION(BlueprintPure)
	ESummitEggBeastState GetState() const
	{
		if (AppliedStates.Num() > 0)
			return AppliedStates.Last().State;

		return ESummitEggBeastState::None;
	}

	UFUNCTION()
	ESummitEggBeastActionState GetActionState() const
	{
		return ActionState;
	}

	UFUNCTION(BlueprintCallable)
	void StartShooting()
	{
		for (auto Player : Game::Players)
		{
			PlayerMoveComps[Player] = UPlayerMovementComponent::Get(Player);
			if (PlayerMoveComps[Player].HasGroundContact())
			{
				PlayerGroundData[Player].GroundLocation = PlayerMoveComps[Player].GroundContact.ImpactPoint;
				PlayerGroundData[Player].bWasGrounded = true;
			}
			else
				PlayerGroundData[Player].bWasGrounded = false;
		}

		if (!HasControl())
			return;

		CrumbSetActionState(ESummitEggBeastActionState::Shooting);

		ActionQueue.Empty();
		ActionQueue.Capability(USummitEggBeastShootActionCapability);
		ActionQueue.SetLooping(true);
	}

	UFUNCTION(BlueprintCallable)
	void StopShooting()
	{
		if (!HasControl())
			return;

		CrumbSetActionState(ESummitEggBeastActionState::None);
		ActionQueue.SetLooping(false);
		ActionQueue.Empty();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetActionState(ESummitEggBeastActionState NewActionState)
	{
		ActionState = NewActionState;
	}

	UFUNCTION()
	void DeactivateStoneBeast()
	{
		// bIsActive = false;
		AddActorDisable(this);
	}
};