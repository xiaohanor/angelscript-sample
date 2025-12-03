event void FSanctuaryCentipedeSlidingBlockSignature();

UCLASS(Abstract)
class USanctuaryCentipedeSlidingBlockEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartGliding() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChainDetached() {}
}

class ASanctuaryCentipedeSlidingBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = YawRotateRoot)
	UBoxComponent TriggerComp;
	default TriggerComp.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent YawRotateRoot;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryCentipedeSlidingBlockChain> AttachedChains;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShakeLooping;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShakeStartStop;

	UPROPERTY()
	FSanctuaryCentipedeSlidingBlockSignature OnStartSliding;

	UPROPERTY()
	FRuntimeFloatCurve YawRotationFloatCurve;

	float SplineProgress = 0.0;
	FVector RelativeLocation;
	FRotator RelativeRotation;
	FHazeAcceleratedRotator AcceleratedRotation;

	float Speed = 0.0;
	float TargetSpeed = 2000.0;

	bool bDetached = false;

	bool bCollisionEnabled = false;

	TPerPlayer<bool> bPlayerInVolume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);
		RelativeLocation = ActorLocation - SplineComp.GetWorldLocationAtSplineDistance(SplineProgress);

		for (auto AttachedChain : AttachedChains)
		{
			AttachedChain.OnBreak.AddUFunction(this, n"HandleChainBreak");
		}

		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");
	}

	UFUNCTION()
	private void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                          const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
			bPlayerInVolume[Player] = true;

		if (bPlayerInVolume[Player.OtherPlayer] && !bCollisionEnabled)
		{
			bCollisionEnabled = true;
			BP_EnableCollision();
		}
	}

	UFUNCTION()
	private void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
			bPlayerInVolume[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDetached)
		{
			if (Speed < TargetSpeed)
				Speed += 200.0 * DeltaSeconds;

			SplineProgress += Speed * DeltaSeconds;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				float FFFrequency = 30.0;
				float FFIntensity = 0.4;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF, 0.5);
			}

			if (SplineProgress > SplineComp.SplineLength)
			{
				SplineProgress = SplineComp.SplineLength;
				bDetached = false;
				CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
				USanctuaryCentipedeSlidingBlockEventHandler::Trigger_OnImpact(this);
				BP_DisableCollision();

				for (AHazePlayerCharacter Player : Game::Players)
					Player.StopCameraShakeByInstigator(this);

				// We is done! Stop inheriting centipede actor movement
				ACentipede Centipede = TListedActors<ACentipede>().Single;
				if (Centipede != nullptr)
					Centipede.bBodyInheritsActorMovement = false;
			}
		}

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress) + RelativeLocation;

		//FRotator Rotation = SplineComp.GetWorldForwardVectorAtSplineDistance(SplineProgress).VectorPlaneProject(FVector::UpVector).Rotation() + RelativeRotation;
		
		float SplineAlpha = SplineProgress / SplineComp.SplineLength;
	
		//SetActorLocationAndRotation(Location, AcceleratedRotation.Value);
		SetActorLocation(Location);

		FRotator Rotation = FRotator(0.0, YawRotationFloatCurve.GetFloatValue(SplineAlpha), 0.0);
		AcceleratedRotation.AccelerateTo(Rotation, 3.0, DeltaSeconds);
		YawRotateRoot.SetRelativeRotation(AcceleratedRotation.Value);
	}

	UFUNCTION()
	private void HandleChainBreak(ASanctuaryCentipedeSlidingBlockChain BrokenChain)
	{
		bool bAllChainsBroken = true;

		USanctuaryCentipedeSlidingBlockEventHandler::Trigger_OnChainDetached(BrokenChain);

		for (auto AttachedChain : AttachedChains)
		{
			if (!AttachedChain.bBroken)
				bAllChainsBroken = false;
		}

		if (bAllChainsBroken)
			Activate();
	}

	UFUNCTION()
	void Activate()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CamShakeStartStop, this);
			Player.PlayCameraShake(CamShakeLooping, this);
		}

		USanctuaryCentipedeSlidingBlockEventHandler::Trigger_StartGliding(this);
		bDetached = true;

		// Make cenitpede body inherit movement
		ACentipede Centipede = TListedActors<ACentipede>().Single;
		if (Centipede != nullptr)
			Centipede.bBodyInheritsActorMovement = true;
		
		OnStartSliding.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_EnableCollision(){}

	UFUNCTION(BlueprintEvent)
	private void BP_DisableCollision(){}
};