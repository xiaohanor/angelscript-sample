enum EThrowableMonkeyState
{
	MovingToPillar,
	OnPillar,
	Grabbed,
	Thrown,
	MovingToPlayer,
	OnFace,
	ThrownOff,
	Despawned
}

asset FDanceShowdownThrowableMonkeyCapabilitySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UDanceShowdownThrowableMonkeyThrowCapability);
	Capabilities.Add(UDanceShowdownThrowableMonkeyInAirCapability);
	Capabilities.Add(UDanceShowdownThrowableMonkeyFlyAwayCapability);
	Capabilities.Add(UDanceShowdownThrowableMonkeyOnPlayerCapability);
	Capabilities.Add(UDanceShowdownThrowableMonkeyGetOnPillarCapability);
	Capabilities.Add(UDanceShowdownThrowableMonkeyOnPillarCapability);
}

class ADanceShowdownThrowableMonkey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(FDanceShowdownThrowableMonkeyCapabilitySheet);

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams JumpAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams LandAnim;
	UPROPERTY(EditDefaultsOnly)

	FHazePlaySlotAnimationParams HandAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams InAirAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams OnPlayerAnim;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve JumpHeightCurve;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SlamForceFeedbackRight;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SlamForceFeedbackLeft;

	UPROPERTY(EditDefaultsOnly)
	float FlyToPlayerSpeed = 4500;

	UPROPERTY(EditDefaultsOnly)
	float FlyAwaySpeed = 2000;
	
	UPROPERTY(EditDefaultsOnly)
	float FlyAwayRotationSpeed = 480;

	UDanceShowdownPlayerComponent TargetPlayer;
	UHazeCharacterSkeletalMeshComponent TargetPlayerMesh;

	UPROPERTY()
	EThrowableMonkeyState State = EThrowableMonkeyState::Despawned;

	int WiggleInput;

	float FlyAwayDirection;

	const FVector RelativeOffsetToHead = FVector(0, 0, -30);

	AHazeActor CurrentPillar;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
	}

	void SetTargetPlayer(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		NetSetTargetPlayer(UDanceShowdownPlayerComponent::Get(Player));
	}

	UFUNCTION(NetFunction)
	private void NetSetTargetPlayer(UDanceShowdownPlayerComponent Player)
	{
		TargetPlayer = Player;
		TargetPlayerMesh = UTundraPlayerShapeshiftingComponent::Get(TargetPlayer.Player).GetMeshForShapeType(ETundraShapeshiftShape::Big);
	}

	void Wiggle(int Input)
	{
		WiggleInput = Input;
	}

	UFUNCTION(NetFunction)
	void NetFlingMonkey(float Direction, float Time)
	{
		State = EThrowableMonkeyState::ThrownOff;
		DetachFromActor(EDetachmentRule::KeepWorld);
		TargetPlayer.RemoveMonkey(Time);
		FlyAwayDirection = Direction;
	}

	void OnFinishedRemoving()
	{
		State = EThrowableMonkeyState::Despawned;
		AddActorVisualsBlock(this);
	}

	FVector GetTargetHeadLocation() const
	{
		check(TargetPlayer != nullptr);
		return TargetPlayerMesh.GetSocketLocation(n"Head") + RelativeOffsetToHead;
	}

	void PlayForceFeedback(bool bRightArm)
	{
		if(TargetPlayer != nullptr)
		{
			if(bRightArm)
				TargetPlayer.Player.PlayForceFeedback(SlamForceFeedbackRight, false, false, this);
			else
				TargetPlayer.Player.PlayForceFeedback(SlamForceFeedbackLeft, false, false, this);
		}
	}
};