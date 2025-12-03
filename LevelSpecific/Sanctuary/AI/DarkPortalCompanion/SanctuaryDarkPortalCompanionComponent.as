enum EDarkPortalCompanionState
{
	Follow,
	Obstructed,
	LaunchStart,
	Launched,
	AtPortal,
	PortalExit,
	Investigating,
	InvestigatingAttached,
}

enum EDarkPortalInvestigationType
{
	Attach, 	// Land at destination
	Flyby, 		// Fly there and then return
}

struct FDarkPortalInvestigationDestination
{
	UPROPERTY(NotVisible)
	USceneComponent TargetComp = nullptr;
	
	UPROPERTY()
	bool bOverridePlayerControl = true;
	
	UPROPERTY()
	EDarkPortalInvestigationType Type = EDarkPortalInvestigationType::Attach;
	
	UPROPERTY()
	float OverrideSpeed = 0.0;	

	UPROPERTY()
	bool bUseObjectRotation = false;
	
	FDarkPortalInvestigationDestination(bool OverridePlayerControl)
	{
		bOverridePlayerControl = OverridePlayerControl;
	}

	FVector GetLocation() const property
	{
		return TargetComp.WorldLocation;
	}

	FTransform GetTransform() const property
	{
		return TargetComp.WorldTransform;
	}

	bool IsValid() const
	{
		if ((TargetComp == nullptr) || TargetComp.IsBeingDestroyed())
			return false;
		return true;
	}

	bool opEquals(FDarkPortalInvestigationDestination Other) const
	{
		if (TargetComp != Other.TargetComp)
			return false;
		if (bOverridePlayerControl != Other.bOverridePlayerControl)
			return false;
		if (!Math::IsNearlyEqual(OverrideSpeed, Other.OverrideSpeed, 1.0))
			return false;
		if (Type != Other.Type)
			return false;
		return true;
	}
}

class USanctuaryDarkPortalCompanionComponent : UActorComponent
{
	// DEPRECATED
	UPROPERTY()
	UNiagaraSystem CrawlyTentacle;
	UPROPERTY()
	UNiagaraSystem FloatyTentacle;
	bool bTentacleReset = false;
	FVector JumpNormal = FVector::ZeroVector;
	TInstigated<bool> bTeleportingMovement;
	default bTeleportingMovement.SetDefaultValue(false);
	bool bReplaceWeaponPortal = false;
	// DEPRECATED

	private AHazePlayerCharacter CompanionToPlayer;
	ADarkPortalActor Portal;
	TArray<FInstigator> PortalOpeners;
	EDarkPortalCompanionState State = EDarkPortalCompanionState::Follow;

	FHazeAcceleratedVector PlayerGroundVelocity;
	UPlayerMovementComponent PlayerMoveComp;

	UDarkPortalUserComponent UserComp;
	bool bObstructed = false;

	float LastPortalTime = -BIG_NUMBER;
	FTransform LastPortalTransform;

	TInstigated<FDarkPortalInvestigationDestination> InvestigationDestination; 

	FHitResult FollowObstruction;
	float FollowObstructedTime = -BIG_NUMBER;	
	float FollowTeleportCooldown = 0.0;

	float LastLaunchedTime = -BIG_NUMBER;

	TInstigated<float> TargetMeshPitch; 

	UPROPERTY(EditAnywhere)
	bool bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FDarkPortalInvestigationDestination InvestigationDefault;
		InvestigationDefault.bOverridePlayerControl = false;			
		InvestigationDestination.DefaultValue = InvestigationDefault;
	}

	AHazePlayerCharacter GetPlayer() property
	{
		return CompanionToPlayer;
	}

	void SetPlayer(AHazePlayerCharacter _Player) property
	{
		CompanionToPlayer = _Player;
		Owner.SetActorControlSide(_Player);
		PlayerGroundVelocity.SnapTo(FVector::ZeroVector);
	}

	FVector UpdatePlayerGroundVelocity(float DeltaTime)
	{
		// Add velocity of any moving platform our player is standing on
		if (Player == nullptr)
			return FVector::ZeroVector;
		if (PlayerMoveComp == nullptr)
			PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		PlayerGroundVelocity.AccelerateTo(PlayerMoveComp.GetFollowVelocity(), 1.0, DeltaTime);
		return PlayerGroundVelocity.Value;
	}

	void Attach(USceneComponent SceneComponent, FName SocketName = NAME_None)
	{
		if (SceneComponent == nullptr)
		{
			devError(f"Attempting to attach to invalid scene component.");
			return;
		}

		if (Owner.RootComponent.AttachParent != nullptr)
			Detach();

		Owner.AttachToComponent(SceneComponent, SocketName, EAttachmentRule::KeepWorld);
	}

	void Detach()
	{
		if (Owner.RootComponent.AttachParent == nullptr)
			return;
		Owner.DetachRootComponentFromParent();
	}

	bool IsFreeFlying()
	{	
		if (Portal == nullptr)
			return true;
		if (State == EDarkPortalCompanionState::Follow)
			return true;
		if (State == EDarkPortalCompanionState::Obstructed)
			return true;
		return false;
	}
}
