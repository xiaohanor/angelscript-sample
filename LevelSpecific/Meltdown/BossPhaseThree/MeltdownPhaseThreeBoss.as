enum EMeltdownPhasThreeOgreShakeState
{
	Move, 
	Shake,
	Done,
}

enum EMeltdownPhaseThreeAttack
{
	None,

	OgreShaker,
	Decimator,
	IceKing,
}

event void FMeltdownPhaseThreeAttackFinished();
event void FMeltdownPhaseThreeVO();

class AMeltdownPhaseThreeBoss : AMeltdownBoss
{
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownBossPhaseThreePunchotronsAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseThreeRaderAnimationCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseThreeOgreAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseThreeDecimatorAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseThreeIceKingAttackCapability);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UHazeCharacterSkeletalMeshComponent PortalMesh;
	default PortalMesh.bHiddenInGame = true;
	default PortalMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

	FName CurrentLocomotionTag;
	FName PortalLocomotionTag;
	bool bIsAttacking = false;
	bool bHasLoopedAttackPattern = false;

	const float ArenaRadius = 2350;

	EMeltdownPhaseThreeAttack CurrentAttack = EMeltdownPhaseThreeAttack::None;

	EMeltdownPhasThreeOgreShakeState OgreState;

	UPROPERTY()
	FMeltdownPhaseThreeAttackFinished OnPunchotronAttackFinished;
	UPROPERTY()
	FMeltdownPhaseThreeAttackFinished OnDecimatorAttackFinished;
	UPROPERTY()
	FMeltdownPhaseThreeAttackFinished OnExecutionerAttackFinished;
	UPROPERTY()
	FMeltdownPhaseThreeAttackFinished OnIceKingAttackFinished;

	UPROPERTY()
	TSubclassOf<AMeltdownPhaseThreeBallDebris> BallDebrisClass;

	UPROPERTY()
	TArray<TSubclassOf<AMeltdownBossPhaseThreePunchotrons>> PunchotronsClasses;
	UPROPERTY()
	TArray<TSubclassOf<AMeltdownPileOfPunchotrons>> PileOfPunchotronsClasses;
	UPROPERTY()
	int PunchotronClassIndex = 0;

	bool bPunchotronAttackActive = false;
	bool bPunchotronSpawnLeft = false;
	bool bPunchotronSpawnRight = false;

	UPROPERTY()
	TSubclassOf<AMeltdownPhaseThreeIceKing> IceKingClass;
	UPROPERTY()
	TSubclassOf<AMeltdownPhaseThreeIceKingClawAttack> ClawAttackClass;
	UPROPERTY()
	TSubclassOf<AMeltdownPhaseThreeDecimator> DecimatorClass;
	int BombCount = 0;

	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;

	UPROPERTY()
	USkeletalMesh DiscPortalMesh;
	UPROPERTY()
	USkeletalMesh SpherePortalMesh;

	UPROPERTY()
	UTexture2D PortalTextureIceKing;
	UPROPERTY()
	UTexture2D PortalTextureOgre;
	UPROPERTY()
	UTexture2D PortalTextureDecimator;
	UPROPERTY()
	UTexture2D PortalTexturePunchotron;
	UPROPERTY()
	UTexture2D PortalTextureExecutioner;

	UPROPERTY()
	UMaterialInterface HydraPortalMat;

	UPROPERTY()
	UMaterialInterface OtherPortalMat;

	UPROPERTY()
	FMeltdownPhaseThreeVO OnStartPunchotronAttack;

	UPROPERTY()
	FMeltdownPhaseThreeVO OnStopPunchotronAttack;

	UPROPERTY()
	FMeltdownPhaseThreeVO OnStartIcekingAttack;

	UPROPERTY()
	FMeltdownPhaseThreeVO OnStartDecimatorAttack;	

	UPROPERTY()
	FMeltdownPhaseThreeVO OnStartOgreAttack;	

	UFUNCTION()
	void StartAttack(EMeltdownPhaseThreeAttack Attack)
	{
		CurrentAttack = Attack;
		
		if(CurrentAttack == EMeltdownPhaseThreeAttack::IceKing)
		{
			SetPortalState(PortalMesh, PortalTextureIceKing);
			OnStartIcekingAttack.Broadcast();
		}
			
		if(CurrentAttack == EMeltdownPhaseThreeAttack::OgreShaker)
		{
			SetPortalState(PortalMesh, PortalTextureOgre);
			OnStartOgreAttack.Broadcast();
		}
			
		if(CurrentAttack == EMeltdownPhaseThreeAttack::Decimator)
		{
			SetPortalState(PortalMesh, PortalTextureDecimator);
			OnStartDecimatorAttack.Broadcast();
		}
	}

	UFUNCTION()
	void StopAttacking()
	{
		CurrentAttack = EMeltdownPhaseThreeAttack::None;
	}

	void OnReachedThreshold() override
	{
		auto SpinnerComp = UMeltdownBossPhaseThreeSpinnerAttackComponent::Get(this);
		if (SpinnerComp != nullptr && SpinnerComp.Spinner != nullptr)
			SpinnerComp.Spinner.AddActorVisualsBlock(this);
		if (SpinnerComp != nullptr && SpinnerComp.LeftMolePortal != nullptr)
			SpinnerComp.LeftMolePortal.AddActorVisualsBlock(this);
		if (SpinnerComp != nullptr && SpinnerComp.RightMolePortal != nullptr)
			SpinnerComp.RightMolePortal.AddActorVisualsBlock(this);

		PortalMesh.AddComponentVisualsBlocker(n"RaderDead");
		Material::SetVectorParameterValue(GlobalParameters, n"RaderPortalClipSphere0", FLinearColor(0, 0, 0, 0));
	}

	void SetPortalState(UMeshComponent Target, UTexture2D Texture, int PortalState = 0)
	{
		if(PortalState == 1)
			Target.SetMaterial(0, HydraPortalMat);
		else
			Target.SetMaterial(0, OtherPortalMat);

		Target.SetTextureParameterValueOnMaterials(n"CubeTexture", Texture);
		Target.SetScalarParameterValueOnMaterials(n"PortalState", PortalState);
	}
	
	void SetPortalClipSphereEnabled(UMeshComponent Target, bool bEnabled)
	{
		if(!HasActorBegunPlay())
			return;

		if(bEnabled && !IsDead())
		{
			FVector Pos = Target.GetSocketLocation(n"Base") + Target.GetSocketRotation(n"Base").UpVector * -4900;
			Material::SetVectorParameterValue(GlobalParameters, n"RaderPortalClipSphere0", FLinearColor(Pos.X, Pos.Y, Pos.Z, 5000));
			//Debug::DrawDebugSphere(Pos, 5000, 20, FLinearColor::Red, 10, 0.5);
		}
		else
		{
			Material::SetVectorParameterValue(GlobalParameters, n"RaderPortalClipSphere0", FLinearColor(0, 0, 0, 0));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		CapsuleComponent.AttachToComponent(Mesh, n"Spine1");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Material::SetVectorParameterValue(GlobalParameters, n"RaderPortalClipSphere0", FLinearColor(0, 0, 0, 0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPunchotronAttackActive)
		{
			SetPortalClipSphereEnabled(PortalMesh, true);
		}
		Super::Tick(DeltaSeconds);
	}

	UFUNCTION()
	void StartPunchotronAttack()
	{
		bPunchotronAttackActive = true;
		SetPortalState(PortalMesh, PortalTexturePunchotron);
		OnStartPunchotronAttack.Broadcast();
		SetPortalClipSphereEnabled(PortalMesh, true);
	}
	
	UFUNCTION()
	void StopPunchotronAttack()
	{
		bPunchotronAttackActive = false;
		OnStopPunchotronAttack.Broadcast();
		SetPortalClipSphereEnabled(PortalMesh, false);
	}
}

class UMeltdownPhaseThreeRaderAnimationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	AMeltdownPhaseThreeBoss Rader;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(Rader.CurrentLocomotionTag, this);

		if (!Rader.PortalLocomotionTag.IsNone())
		{
			Rader.PortalMesh.SetHiddenInGame(false);
			if (Rader.PortalMesh.CanRequestLocomotion())
				Rader.PortalMesh.RequestLocomotion(Rader.PortalLocomotionTag, this);
		}
		else
		{
			Rader.PortalMesh.SetHiddenInGame(true);
		}
	}
}