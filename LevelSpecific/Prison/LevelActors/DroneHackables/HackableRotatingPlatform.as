
UCLASS(Abstract)
class AHackableRotatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;
	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(DefaultComponent)
	USceneComponent SpinningFanRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent WidgetComponent;

	UPROPERTY(DefaultComponent, Attach = SpinningFanRoot)
	USceneComponent FanRotationRoot;

	UPROPERTY(DefaultComponent, Attach = SpinningFanRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableRotatingPlatformCapability");

	UPROPERTY(EditAnywhere)
	float Speed = 50;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"HackingStarted");
		HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"HackingStopped");
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		OnHackingStopped.Broadcast();
	}
};

class UHackableRotatingPlatformCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableRotatingPlatform RotatingPlatform;
	AHazePlayerCharacter Player;

	UHazeMovementComponent PlayerMoveComp;

	float RotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RotatingPlatform = Cast<AHackableRotatingPlatform>(Owner);
		Player = Drone::GetSwarmDronePlayer();
			PlayerMoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!RotatingPlatform.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!RotatingPlatform.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		FVector Input = PlayerMoveComp.MovementInput;

		FRotator Rotation;
		Rotation.Yaw = Input.X * RotatingPlatform.Speed * DeltaTime;

		RotatingPlatform.RootComp.AddRelativeRotation(Rotation);
	}
}