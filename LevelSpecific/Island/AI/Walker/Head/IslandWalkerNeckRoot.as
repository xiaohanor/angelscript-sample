event void FOnNeckTargetSetupSignature(AIslandWalkerNeckTarget Target);
event void FOnHeadSetupSignature(AIslandWalkerHead Head);

UCLASS(HideCategories = "Rendering ComponentTick Advanced Disable Debug Activation Cooking LOD Collision")
class UIslandWalkerNeckRoot : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandWalkerNeckTarget> NeckClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandWalkerHead> HeadClass;

	UPROPERTY()
	EIslandForceFieldType ForceFieldType = EIslandForceFieldType::Red;

	FOnHeadSetupSignature OnHeadSetup;
	FOnNeckTargetSetupSignature OnNeckTargetSetup;

	UHazeSkeletalMeshComponentBase Mesh;
	AIslandWalkerNeckTarget NeckTarget;
	AIslandWalkerHead Head;

	const FName BaseBone = n"Head";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	void SetupTarget()
	{
		NeckTarget = SpawnActor(NeckClass, bDeferredSpawn = true, Level = Owner.Level);
		NeckTarget.MakeNetworked(this, n"NeckTarget");
		NeckTarget.OwnerWalker = Cast<AHazeCharacter>(Owner);
		NeckTarget.ForceFieldComp.Walker = NeckTarget.OwnerWalker;
		NeckTarget.ForceFieldComp.Type = ForceFieldType;
		FinishSpawningActor(NeckTarget);

		NeckTarget.AttachToComponent(NeckTarget.OwnerWalker.Mesh, n"NeckHitTarget", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);

		OnNeckTargetSetup.Broadcast(NeckTarget);
	}

	void SetupHead()
	{
		Head = SpawnActor(HeadClass, bDeferredSpawn = true, Level = Owner.Level);
		Head.MakeNetworked(Owner, BaseBone);
		Head.HeadComp.NeckCableOrigin = UIslandWalkerCableOriginComponent::Get(Owner);
		FinishSpawningActor(Head);

		Head.AttachToComponent(this, NAME_None, EAttachmentRule::SnapToTarget);
		Head.ActorRelativeLocation = FVector(0.0, 0.0, 0.0);
		Head.ActorRelativeRotation = FRotator(0.0,0.0, 0.0);
		Head.ActorScale3D = FVector::OneVector;

		// Hide head until it's time to detach
		Head.Mesh.AddComponentVisualsBlocker(this);

		OnHeadSetup.Broadcast(Head);
	}

	void DeployHead()
	{
		if (!ensure(Head.HeadComp.State == EIslandWalkerHeadState::Attached))
			return;

		Head.HeadComp.State = EIslandWalkerHeadState::Deployed;	}

	void SwapHead()
	{
		// Hide walker mesh head and show head actor
		Cast<AHazeCharacter>(Owner).Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
		Head.Mesh.RemoveComponentVisualsBlocker(this);
	}

	void DetachHead()
	{
		if(Head.HeadComp.State != EIslandWalkerHeadState::Detached)
		{
			auto Walker = Cast<AAIIslandWalker>(Outer);
			Head.AttachDefaultSoundDefs(Walker.WalkerHeadSoundDefs);
		}

		// Note that this occurs when head is out of sight, effects will have been triggered earlier
		Head.HeadComp.State = EIslandWalkerHeadState::Detached;
		auto PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		if (PhaseComp.Phase < EIslandWalkerPhase::Decapitated)
			PhaseComp.Phase = EIslandWalkerPhase::Decapitated;
		Head.DetachRootComponentFromParent(true);

		// Ignite thrusters immediately so they'll be burning during transition cutscene
		for (UIslandWalkerHeadThruster Thruster : Head.ThrusterAssembly.Thrusters)
		{
			Thruster.Deploy();
			Thruster.Ignite();		
		}
	}
};

// Hack test to cover neck force field from below
class UIslandWalkerNeckCoverRoot : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	UIslandWalkerNeckRoot NeckRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		 NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		 UIslandWalkerPhaseComponent::Get(Owner).OnPhaseChange.AddUFunction(this, n"OnPhaseChange");
	}

	UFUNCTION()
	private void OnPhaseChange(EIslandWalkerPhase NewPhase)
	{
		// if (NewPhase == EIslandWalkerPhase::Suspended)
		// 	SetComponentTickEnabled(true);
		// else
		// 	SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (NeckRoot.NeckTarget == nullptr)
			return;
		
		FVector NewLoc = RelativeLocation;
		if (NeckRoot.NeckTarget.GrenadeTargetableComp.IsDisabled())
			NewLoc.Z = Math::Max(0.0, RelativeLocation.Z - DeltaTime * 40.0); // Slide down
		else
			NewLoc.Z = Math::Min(80.0, RelativeLocation.Z + DeltaTime * 40.0); // Slide up
		RelativeLocation = NewLoc;
	}
}

