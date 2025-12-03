UCLASS(Abstract)
class USkylineJumpPadEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch()
	{
	}
};

class USkylineJumpPadPusharComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	float SineOffset = 0.0;

	FHazeAcceleratedFloat ZValue;
	float SineFreq = 3.0;
	float SineDistance = 5.0;
	float PushDistance = 300.0;

	float PushDuration = 0.5;
	float ResetTime = -1.0;

	bool bPushing = false;

	float SineTarget = 0.0;

	USceneComponent AttachedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachedComp = GetChildComponent(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SineTarget = Math::Sin(Time::GameTimeSeconds * SineFreq + (SineOffset * 3.0)) * SineDistance;

		ZValue.AccelerateTo((bPushing ? 0.0 : SineTarget), 0.2, DeltaSeconds);

		if (Time::GameTimeSeconds > ResetTime)
			bPushing = false;
	
		AttachedComp.SetRelativeLocation(FVector::UpVector * ZValue.Value);
	}

	void Push()
	{
		bPushing = true;
		ResetTime = Time::GameTimeSeconds + PushDuration;
	}
}
event void FSkylineJumpPadignature();

class ASkylineJumpPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger;
	default Trigger.BoxExtent = FVector(50.0, 50.0, 50.0,);
	default Trigger.bGenerateOverlapEvents = false;
	default Trigger.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	
	TArray<USkylineJumpPadPusharComponent> PusharComps;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector TargetLocation;

	UPROPERTY()
	FSkylineJumpPadignature OnPlayerLaunched;

	UPROPERTY(EditAnywhere)
	float JumpHeight = 2000.0;

	UPROPERTY(EditAnywhere)
	float Cooldown = 1.0;

	UPROPERTY(EditAnywhere)
	AActor TargetPoint;

	bool bHasLaunched = false;
	float ActivationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDectivated");
	
		GetComponentsByClass(PusharComps);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHasLaunched && Time::GameTimeSeconds > ActivationTime + Cooldown)
		{
			InterfaceComp.TriggerActivate();
			bHasLaunched = false;
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		if (Game::Zoe.HasControl())
			CrumbLaunch();
	}

	UFUNCTION()
	private void HandleDectivated(AActor Caller)
	{
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch()
	{
		for (auto PusharComp : PusharComps)
			PusharComp.Push();

		auto Trace = Trace::InitFromPrimitiveComponent(Trigger);
		auto Overlaps = Trace.QueryOverlaps(Trigger.WorldLocation);

		TranslateComp.ApplyImpulse(TranslateComp.WorldLocation, TranslateComp.UpVector * 1000.0);

		for (auto Overlap : Overlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player == nullptr)
				continue;

			// Mio can't use these jump pads, because she's the one that triggers them
			if (Player.IsMio())
				continue;

			auto LaunchComp = USkylineLaunchPadUserComponent::Get(Player);
			FVector TargetLocationWorld = ActorTransform.TransformPositionNoScale(TargetLocation);

			if (TargetPoint != nullptr)
				TargetLocationWorld = TargetPoint.ActorLocation;

		
			Player.FlagForLaunchAnimations(FVector(1000.0,1000.0,1000));
			Player.PlayForceFeedback(ForceFeedback,false,false,this, 2.0);
			Player.PlayCameraShake(CameraShake, this);
			
			LaunchComp.Launch(TargetLocationWorld, JumpHeight);
			OnPlayerLaunched.Broadcast();
//				Debug::DrawDebugPoint(TargetLocationWorld, 100.0, FLinearColor::Green, 5.0);
		}
	
		InterfaceComp.TriggerDeactivate();

		ActivationTime = Time::GameTimeSeconds;
		bHasLaunched = true;

		BP_OnLaunch();

		USkylineJumpPadEventHandler::Trigger_OnLaunch(this);
	}

	/* BlueprintEvents */
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_OnLaunch() {}
};