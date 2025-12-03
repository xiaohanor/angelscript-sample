event void FPinballBallOnPushedByPlunger(FPinballBallPushedByPlungerData PushedByPlungerData);
event void FPinballBallOnLaunched(FPinballBallLaunchData LaunchData);
delegate FVector FPinballBallGetVisualLocation();
delegate UPinballLauncherComponent FPinballBallGetLaunchedBy();
event void FPinballBallOnSquished();

struct FPinballBallPushedByPlungerData
{
	APinballPlunger Plunger;
	float InitialHorizontalOffset = 0;
	float InitialAlpha = 0;

	FPinballBallPushedByPlungerData(APinballPlunger InPlunger, FVector InBallLocation)
	{
		Plunger = InPlunger;
		
		const FVector RelativeLocation = Plunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(InBallLocation);
		InitialHorizontalOffset = RelativeLocation.Y;

		InitialAlpha = Plunger.GetCurrentLaunchForwardAlpha();
	}
};

struct FPinballBallLaunchData
{
	FVector LaunchLocation = FVector::ZeroVector;
	FVector VisualLocation = FVector::ZeroVector;
	FVector LaunchVelocity = FVector::ZeroVector;
	UPinballLauncherComponent LaunchedBy = nullptr;
	bool bIsProxy = false;
	bool bFromBallSide = false;

	FPinballBallLaunchData(
		FVector InLaunchLocation,
		FVector InVisualLocation,
		FVector InLaunchVelocity,
		UPinballLauncherComponent InLaunchedBy,
		bool bInIsProxy,
	)
	{
		LaunchLocation = InLaunchLocation;
		VisualLocation = InVisualLocation;
		LaunchVelocity = InLaunchVelocity;
		LaunchedBy = InLaunchedBy;
		bIsProxy = bInIsProxy;
	}

	bool IsValid() const
	{
		return LaunchedBy != nullptr;
	}

	AActor LaunchedByActor() const
	{
		return LaunchedBy.Owner;
	}
};

enum EPinballBallType
{
	Player,
	BossBall,
};

/**
 * Used by all balls in Pinball (Player, BossBall)
 * Should basically be an interface for something getting hit and launched
 */
UCLASS(NotBlueprintable)
class UPinballBallComponent : UActorComponent
{
	access MagnetDrone = private, UPinballMagnetDroneCapability;

	UPROPERTY(EditDefaultsOnly)
	EPinballBallType BallType = EPinballBallType::Player;

	UPROPERTY(EditDefaultsOnly)
	bool bCanBeSquished = true;

	UPROPERTY(EditDefaultsOnly)
	bool bAllowLerpingWhileLaunchingOnPlungers = true;

	UPROPERTY(EditDefaultsOnly)
	bool bOverrideRadius = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bOverrideRadius"))
	float OverrideRadius = MagnetDrone::Radius;

	UPROPERTY()
	FPinballBallOnPushedByPlunger OnPushedByPlunger;

	UPROPERTY()
	FPinballBallOnLaunched OnLaunched;

	UPROPERTY(NotEditable)
	FPinballBallGetVisualLocation GetVisualLocationDelegate;

	UPROPERTY(NotEditable)
	FPinballBallGetLaunchedBy GetLaunchedByDelegate;

	UPROPERTY()
	FPinballBallOnSquished OnSquished;

	AHazeActor HazeOwner;
	UHazeMovementComponent MoveComp;

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEmitter BallEmitter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pinball::GetManager().Balls.Add(this);
		HazeOwner = Cast<AHazeActor>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);

		UMovementStandardSettings::SetWalkableSlopeAngle(HazeOwner, Pinball::Movement::MaxSlopeAngle, this);

		FHazeAudioEmitterAttachmentParams EmitterParams;
		EmitterParams.Owner = this;
		EmitterParams.Instigator = this;
		EmitterParams.Attachment = Owner.RootComponent;
		
		#if TEST
		EmitterParams.EmitterName = FName(f"{GetName()}_BallEmitter");
		#endif

		BallEmitter = Audio::GetPooledEmitter(EmitterParams); 

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballBall");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Pinball::GetManager().Balls.RemoveSingle(this);
		Audio::ReturnPooledEmitter(this, BallEmitter);
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayer() const
	{
		return BallType == EPinballBallType::Player;
	}

	void Launch(FPinballBallLaunchData LaunchData)
	{
		OnLaunched.Broadcast(LaunchData);
	}

	/**
	 * Called from Net synced launches
	 */
	void BroadcastOnLaunchedEvent(FPinballBallLaunchData LaunchData)
	{
		FPinballOnLaunchedEventData EventData(LaunchData);
		UPinballBallEventHandler::Trigger_OnLaunched(HazeOwner, EventData);
	}

	void Squish()
	{
		if(!bCanBeSquished)
			return;

		OnSquished.Broadcast();
	}

	float GetRadius() const
	{
		if(bOverrideRadius)
			return OverrideRadius;
		
		return MoveComp.CollisionShape.Shape.SphereRadius;
	}

	FVector GetVisualLocation() const
	{
		if(GetVisualLocationDelegate.IsBound())
			return GetVisualLocationDelegate.Execute();

		return Owner.ActorLocation;
	}
};