asset SimonSaysMonkeySheet of UHazeCapabilitySheet
{
	AddCapability(n"Tundra_SimonSaysMonkeyDanceCapability");
	AddCapability(n"Tundra_SimonSaysMonkeyIdleCapability");
}

struct FTundra_SimonSaysMonkeyAnimData
{
	bool bIsJumping;
	float TurnRate;
	float JumpAlpha;
	float TempoMultiplier = 1.0;
}

UCLASS(Abstract)
class ATundra_SimonSaysMonkey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SimonSaysMonkeySheet);

	UPROPERTY(EditAnywhere)
	EHazePlayer MirroringPlayer;

	/* The current index of the point the monkey is currently standing on */
	UPROPERTY(EditAnywhere)
	int CurrentPointIndex = 2;

	UPROPERTY(EditAnywhere)
	float BezierControlPointHeight = 200.0;

	FTundra_SimonSaysMonkeyAnimData AnimData;
	FRotator OriginalRotation;
	UTundra_SimonSaysMonkeySettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(TundraSimonSays::GetManager() != nullptr, "Using a Tundra_SimonSays monkey, but there is no Tundra_SimonSaysManager in the level!");
		
		Settings = UTundra_SimonSaysMonkeySettings::GetSettings(this);
		OriginalRotation = ActorRotation;
		AnimData.TurnRate = Settings.TurnRate;
	}
}