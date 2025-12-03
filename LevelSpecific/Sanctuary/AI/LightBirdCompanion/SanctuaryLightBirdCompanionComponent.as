enum ELightBirdCompanionState
{
	Follow,
	Obstructed,
	LaunchStart,
	Launched,
	LaunchAttached,
	LaunchExit,
	LanternRecall,
	LanternAttached,
	Investigating,
	InvestigatingAttached
}

enum ELightBirdInvestigationType
{
	Attach, 	// Land at destination
	Flyby, 		// Fly there and then return
}

struct FLightBirdInvestigationDestination
{
	UPROPERTY(NotVisible)
	USceneComponent TargetComp = nullptr;
	
	UPROPERTY()
	bool bOverridePlayerControl = true;
	
	UPROPERTY()
	ELightBirdInvestigationType Type = ELightBirdInvestigationType::Attach;
	
	UPROPERTY()
	float OverrideSpeed = 0.0;	
	
	UPROPERTY()
	bool bAutoIlluminate = false;

	UPROPERTY()
	bool bUseObjectRotation = false;

	FLightBirdInvestigationDestination(bool OverridePlayerControl)
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

	bool opEquals(FLightBirdInvestigationDestination Other) const
	{
		if (TargetComp != Other.TargetComp)
			return false;
		if (bOverridePlayerControl != Other.bOverridePlayerControl)
			return false;
		if (!Math::IsNearlyEqual(OverrideSpeed, Other.OverrideSpeed, 1.0))
			return false;
		if (bAutoIlluminate != Other.bAutoIlluminate)
			return false;
		if (Type != Other.Type)
			return false;
		return true;
	}
}

class USanctuaryLightBirdCompanionComponent : UActorComponent
{
	private AHazePlayerCharacter CompanionToPlayer;
	ULightBirdUserComponent UserComp;
	FHazeAcceleratedVector PlayerGroundVelocity;
	UPlayerMovementComponent PlayerMoveComp;
	UMaterialInstanceDynamic GlowMaterial;
	TArray<FInstigator> Illuminators;
	TArray<FInstigator> ForceIlluminators;

	UPROPERTY()
	ELightBirdCompanionState State = ELightBirdCompanionState::Follow;

	private FVector FollowImpulse = FVector::ZeroVector;
	private float FollowImpulseTime = -BIG_NUMBER;

	private ULightBirdResponseComponent AttachResponse = nullptr;

	TInstigated<FLightBirdInvestigationDestination> InvestigationDestination; 

	FVector LaunchObstructionLoc;
	float LaunchObstructionTime;

	FHitResult FollowObstruction;
	float FollowObstructedTime = -BIG_NUMBER;	
	float FollowTeleportCooldown = 0.0;

	float LastLaunchedTime = -BIG_NUMBER;

	UPROPERTY(EditAnywhere)
	bool bSpecialCaseDelayVisibleAfterFallFromCompanionsCutscene = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FLightBirdInvestigationDestination InvestigationDefault;
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
		UserComp = ULightBirdUserComponent::Get(_Player);
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

		AttachResponse = ULightBirdResponseComponent::Get(SceneComponent.Owner);
		// if (AttachResponse != nullptr && !AttachResponse.IsListener())
		// 	AttachResponse.Attach(Bird);

		Owner.AttachToComponent(SceneComponent, SocketName, EAttachmentRule::KeepWorld);
	}

	void Detach()
	{
		if (Owner.RootComponent.AttachParent == nullptr)
			return;

		if (Owner.AttachParentActor != nullptr && 
			AttachResponse != nullptr &&
			!AttachResponse.IsListener())
		{
			//AttachResponse.Detach(Bird);
			AttachResponse = nullptr;
		}

		Owner.DetachRootComponentFromParent();
	}

	bool IsFreeFlying()
	{	
		if (State == ELightBirdCompanionState::Follow)
			return true;
		if (State == ELightBirdCompanionState::Obstructed)
			return true;
		if (State == ELightBirdCompanionState::LaunchExit)
			return true;
		return false;
	}

	void ApplyFollowImpulse(FVector Impulse)
	{
		FollowImpulse = Impulse;
		FollowImpulseTime = Time::GameTimeSeconds;
	}

	FVector ConsumeFollowImpulse()
	{
		if (Time::GetGameTimeSince(FollowImpulseTime) < 0.5)
		{
			FVector Impulse = FollowImpulse;
			FollowImpulse = FVector::ZeroVector;
			FollowImpulseTime = -BIG_NUMBER;
			return Impulse;
		}
		return FVector::ZeroVector;
	}
}
